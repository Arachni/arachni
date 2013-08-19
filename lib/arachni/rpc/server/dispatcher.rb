=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'socket'
require 'sys/proctable'

module Arachni

require Options.dir['lib'] + 'rpc/client'
require Options.dir['lib'] + 'rpc/server/base'
require Options.dir['lib'] + 'rpc/server/instance'
require Options.dir['lib'] + 'rpc/server/output'

module RPC
class Server

#
# Dispatches RPC Instances on demand providing a centralized environment
# for multiple clients and allows for extensive process monitoring.
#
# The process goes something like this:
#
# * On initialization the Dispatcher populates the Instance pool.
# * A client issues a {#dispatch} call.
# * The Dispatcher pops an Instance from the pool
#   * Asynchronously replenishes the pool
#   * Gives the Instance credentials to the client (url, auth token, etc.)
# * The client connects to the Instance using these credentials.
#
# Once the client finishes using the RPC Instance he *must* shut it down
# otherwise the system will be eaten away by zombie RPC Instance processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Dispatcher
    require Options.dir['lib'] + 'rpc/server/dispatcher/node'
    require Options.dir['lib'] + 'rpc/server/dispatcher/handler'

    include Utilities
    include UI::Output
    include ::Sys

    HANDLER_NAMESPACE = Handler

    def initialize( opts = Options.instance )
        banner

        @opts = opts

        @opts.rpc_port    ||= 7331
        @opts.rpc_address ||= 'localhost'
        @opts.pool_size   ||= 5

        if @opts.help
            print_help
            exit 0
        end

        @server = Base.new( @opts )
        @server.logger.level = @opts.datastore[:log_level] if @opts.datastore[:log_level]

        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        @url = "#{@opts.rpc_address}:#{@opts.rpc_port.to_s}"

        # let the instances in the pool know who to ask for routing instructions
        # when we're in grid mode.
        @opts.datastore[:dispatcher_url] = @url.dup

        prep_logging

        print_status 'Initing RPC Server...'

        @server.add_handler( 'dispatcher', self )

        # trap interrupts and exit cleanly when required
        trap_interrupts { shutdown }

        @jobs          = []
        @consumed_pids = []
        @pool          = ::EM::Queue.new

        if @opts.pool_size > 0
            print_status 'Warming up the pool...'
            @opts.pool_size.times { add_instance_to_pool( false ) }
        end

        # Check up on the pool and start the server once it has been filled.
        timer = ::EM::PeriodicTimer.new( 0.1 ) do
            next if @opts.pool_size != @pool.size
            timer.cancel

            _handlers.each do |name, handler|
                @server.add_handler( name, handler.new( @opts, self ) )
            end

            @node = Node.new( @opts, @logfile )
            @server.add_handler( 'node', @node )

            print_status 'Initialization complete.'

            run
        end
    end

    def handlers
        _handlers.keys
    end

    # @return   [TrueClass]   true
    def alive?
        @server.alive?
    end

    # @return   [String]
    #   URL of the least burdened Dispatcher. If not a grid member it will
    #   return this Dispatcher's URL.
    def preferred( &block )
        if !@node.grid_member?
            block.call @url
            return
        end

        each = proc do |neighbour, iter|
            connect_to_peer( neighbour ).workload_score do |score|
                iter.return (!score || score.rpc_exception?) ? nil : [neighbour, score]
            end
        end

        after = proc do |nodes|
            nodes.compact!
            nodes << [@url, workload_score]
            block.call nodes.sort_by { |_, score| score }[0][0]
        end

        ::EM::Iterator.new( @node.neighbours ).map( each, after )
    end

    #
    # Dispatches an {Instance} from the pool.
    #
    # @param    [String]  owner     An owner to assign to the {Instance}.
    # @param    [Hash]    helpers   Hash of helper data to be added to the job.
    # @param    [Boolean]    load_balance
    #   Return an {Instance} from the least burdened {Dispatcher} (when in Grid mode)
    #   or from this one directly?
    #
    # @return   [Hash, false, nil]
    #   Depending on availability:
    #
    #   * `Hash`: Includes URL, owner, clock info and proc info.
    #   * `false`: Pool is currently empty, check back again in a few seconds.
    #   * `nil`: The {Dispatcher} was configured with a pool-size of `0`.
    #
    def dispatch( owner = 'unknown', helpers = {}, load_balance = true, &block )
        if load_balance && @node.grid_member?
            preferred do |url|
                connect_to_peer( url ).dispatch( owner, helpers, false, &block )
            end
            return
        end

        if @opts.pool_size <= 0
            block.call nil
            return
        end

        if @pool.empty?
            block.call false
        else
            @pool.pop do |cjob|
                cjob['owner']     = owner.to_s
                cjob['starttime'] = Time.now
                cjob['helpers']   = helpers

                print_status "Instance dispatched -- PID: #{cjob['pid']} - " +
                    "Port: #{cjob['port']} - Owner: #{cjob['owner']}"

                @jobs << cjob
                block.call cjob
            end
        end

        ::EM.next_tick { add_instance_to_pool }
    end

    #
    # Returns proc info for a given pid
    #
    # @param    [Fixnum]      pid
    #
    # @return   [Hash]
    #
    def job( pid )
        @jobs.each do |j|
            next if j['pid'] != pid
            cjob = j.dup

            cjob['currtime'] = Time.now
            cjob['age']      = cjob['currtime'] - cjob['birthdate']
            cjob['runtime']  = cjob['currtime'] - cjob['starttime']
            cjob['proc']     = proc_hash( cjob['pid'] )

            return cjob
        end
    end

    # @return   [Array<Hash>]   Returns proc info for all jobs.
    def jobs
        @jobs.map { |cjob| job( cjob['pid'] ) }.compact
    end

    #
    # @return   [Array<Hash>]   Returns proc info for all running jobs.
    #
    # @see #jobs
    #
    def running_jobs
        jobs.reject { |job| job['proc'].empty? }
    end

    #
    # @return   [Array<Hash>]   Returns proc info for all finished jobs.
    #
    # @see #jobs
    #
    def finished_jobs
        jobs.select { |job| job['proc'].empty? }
    end

    # @return   [Float]
    #   Workload score for this Dispatcher, calculated using the number
    #   of {#running_jobs} and the configured node weight.
    #
    #   Lower is better.
    #
    def workload_score
        score = (running_jobs.size + 1).to_f
        score *= @node.info['weight'].to_f if @node.info['weight']
        score
    end

    # @return   [Hash]
    #   Returns server stats regarding the jobs and pool.
    def stats
        stats_h = {
            'running_jobs'   => running_jobs,
            'finished_jobs'  => finished_jobs,
            'init_pool_size' => @opts.pool_size,
            'curr_pool_size' => @pool.size,
            'consumed_pids'  => @consumed_pids
        }

        stats_h.merge!( 'node' => @node.info, 'neighbours' => @node.neighbours )
        stats_h['node']['score']  = workload_score

        stats_h
    end

    # @return   [String]    contents of the log file
    def log
        IO.read prep_logging
    end

    # @return   [Hash]   the server's proc info
    def proc_info
        proc_hash( Process.pid ).merge( 'node' => @node.info )
    end

    private

    def self._handlers
        @handlers ||= nil
        return @handlers if @handlers

        @handlers = Component::Manager.new( Options.dir['rpcd_handlers'], HANDLER_NAMESPACE )
        @handlers.load_all
        @handlers
    end

    def _handlers
        self.class._handlers
    end

    #
    # Outputs the Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    def banner
        puts BANNER
        puts
        puts
    end

    def print_help
        puts <<USAGE
  Usage:  arachni_rpcd \[options\]

  Supported options:

    -h
    --help                      output this

    --address=<host>            specify address to bind to
                                    (Default: #{@opts.rpc_address})

    --port=<num>                specify port to listen to
                                    (Default: #{@opts.rpc_port})

    --port-range=<beginning>-<end>

                                specify port range for the RPC instances
                                    (Make sure to allow for a few hundred ports.)
                                    (Default: #{@opts.rpc_instance_port_range.join( '-' )})

    --reroute-to-logfile        reroute all output to a logfile under 'logs/'

    --pool-size=<num>           how many server workers/processes should be available
                                  at any given moment (Default: #{@opts.pool_size})

    --neighbour=<URL>           URL of a neighbouring Dispatcher (used to build a grid)

    --weight=<float>            weight of the Dispatcher

    --pipe-id=<string>          bandwidth pipe identification

    --nickname=<string>         nickname of the Dispatcher

    --debug


    SSL --------------------------

    (All SSL options will be honored by the dispatched RPC instances as well.)
    (Do *not* use encrypted keys!)

    --ssl-pkey   <file>         location of the server SSL private key (.pem)
                                    (Used to verify the server to the clients.)

    --ssl-cert   <file>         location of the server SSL certificate (.pem)
                                    (Used to verify the server to the clients.)

    --node-ssl-pkey   <file>    location of the client SSL private key (.pem)
                                    (Used to verify this node to other servers.)

    --node-ssl-cert   <file>    location of the client SSL certificate (.pem)
                                    (Used to verify this node to other servers.)

    --ssl-ca     <file>         location of the CA certificate (.pem)

USAGE
    end


    def trap_interrupts( &block )
        %w(QUIT INT).each do |signal|
            trap( signal, &block || Proc.new{ } ) if Signal.list.has_key?( signal )
        end
    end

    # Starts the dispatcher's server
    def run
        print_status 'Starting the server...'
        @server.start
    rescue => e
        print_error e.to_s
        print_error_backtrace e

        $stderr.puts "Could not start server, for details see: #{@logfile}"

        # If the server fails to start kill the pool Instances
        # to prevent zombie processes.
        @consumed_pids.each { |p| kill p }
        exit 1
    end

    def shutdown
        print_status 'Shutting down...'
        @server.shutdown
    end

    def kill( pid )
        begin
            10.times { Process.kill( 'KILL', pid ) }
            return false
        rescue Errno::ESRCH
            return true
        end
    end

    def add_instance_to_pool( one_at_a_time = true )
        return if @operation_in_progress && one_at_a_time
        @operation_in_progress = true

        owner = 'dispatcher'
        exception_jail {

            # get an available port for the child
            port  = available_port
            token = generate_token

            pid = fork do
                @opts.rpc_port = port
                Server::Instance.new( @opts, token )
            end

            # let the child go about its business
            Process.detach( pid )

            print_status "Instance added to pool -- PID: #{pid} - " +
                "Port: #{port} - Owner: #{owner}"

            url = "#{@opts.rpc_address}:#{port}"

            options = OpenStruct.new( @opts.to_h.symbolize_keys( false ) )
            options.max_retries = 0

            client = Client::Instance.new( options, url, token )
            timer = ::EM::PeriodicTimer.new( 0.1 ) do
                client.service.alive? do |r|
                    next if r.rpc_exception?

                    timer.cancel
                    client.close

                    @operation_in_progress = false

                    @pool << {
                        'token'     => token,
                        'pid'       => pid,
                        'port'      => port,
                        'url'       => url,
                        'owner'     => owner,
                        'birthdate' => Time.now
                    }

                    @consumed_pids << pid
                end
            end
        }
    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file( @opts.dir['logs'] +
            "/Dispatcher - #{Process.pid}-#{@opts.rpc_port}.log" )
    end

    def proc_hash( pid )
        struct_to_h( ProcTable.ps( pid ) )
    end

    def connect_to_peer( url )
        Client::Dispatcher.new( @opts, url )
    end

    def struct_to_h( struct )
        hash = {}
        return hash if !struct

        struct.each_pair do |k, v|
            v = v.to_s if v.is_a?( Bignum ) || v.is_a?( Fixnum )
            hash[k.to_s] = v
        end

        hash
    end

end

end
end
end
