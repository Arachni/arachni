=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# * on init the Dispatcher populates an Instance pool
# * a client issues a 'dispatch' call
# * the Dispatcher pops an Instance from the pool
#   * asynchronously replenishes the pool
#   * gives the Instance credentials to the client (url, auth token, etc.)
# * the client connects to the Instance using these credentials
#
# Once the client finishes using the RPC Instance he *must* shut it down otherwise
# the system will be eaten away by zombie RPC Instance processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Dispatcher
    require Options.dir['lib'] + 'rpc/server/dispatcher/node'
    require Options.dir['lib'] + 'rpc/server/dispatcher/handler'

    include Utilities
    include UI::Output
    include ::Sys


    HANDLER_LIB       = Options.dir['rpcd_handlers']
    HANDLER_NAMESPACE = Handler

    def initialize( opts )
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

        # let the instances in the pool know who to ask for routing instructions
        # when we're in grid mode.
        @opts.datastore[:dispatcher_url] = "#{@opts.rpc_address}:#{@opts.rpc_port.to_s}"

        prep_logging

        print_status 'Initing RPC Server...'

        @server.add_handler( 'dispatcher', self )

        # trap interrupts and exit cleanly when required
        trap_interrupts { shutdown }

        @jobs = []
        @consumed_pids = []
        @pool = ::EM::Queue.new

        if @opts.pool_size > 0
            print_status 'Warming up the pool...'
            @opts.pool_size.times{ add_instance_to_pool }
        end

        print_status 'Initialization complete.'

        @node = Node.new( @opts, @logfile )
        @server.add_handler( 'node', @node )

        _handlers.each do |name, handler|
            @server.add_handler( name, handler.new( @opts, self ) )
        end

        run
    end

    def handlers
        _handlers.keys
    end

    # @return   [TrueClass]   true
    def alive?
        @server.alive?
    end

    #
    # Dispatches an RPC server instance from the pool
    #
    # @param    [String]  owner     an owner assign to the dispatched RPC server
    # @param    [Hash]    helpers   hash of helper data to be added to the job
    #
    # @return   [Hash]      includes port number, owner, clock info and proc info
    #
    def dispatch( owner = 'unknown', helpers = {}, &block )
        if @opts.pool_size <= 0
            block.call false
            return
        end

        # just to make sure...
        owner = owner.to_s
        ::EM.next_tick { add_instance_to_pool }
        @pool.pop do |cjob|
            cjob['owner']     = owner
            cjob['starttime'] = Time.now
            cjob['helpers']   = helpers

            print_status "Instance dispatched -- PID: #{cjob['pid']} - " +
                "Port: #{cjob['port']} - Owner: #{cjob['owner']}"

            @jobs << cjob

            block.call cjob
        end
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
            cjob['proc']     = proc( cjob['pid'] )

            return cjob
        end
    end

    #
    # Returns proc info for all jobs
    #
    # @return   [Array<Hash>]
    #
    def jobs
        @jobs.map { |cjob| job( cjob['pid'] ) }.compact
    end

    #
    # Returns server stats regarding the jobs and pool
    #
    # @return   [Hash]
    #
    def stats
        cjobs    = jobs( )
        running  = cjobs.reject { |job| job['proc'].empty? }
        finished = cjobs - running

        stats_h = {
            'running_jobs'   => running,
            'finished_jobs'  => finished,
            'init_pool_size' => @opts.pool_size,
            'curr_pool_size' => @pool.size,
            'consumed_pids'  => @consumed_pids
        }

        stats_h.merge!( 'node' => @node.info, 'neighbours' => @node.neighbours )

        stats_h['node']['score']  = (rs_score = resource_consumption_score) > 0 ? rs_score : 1
        stats_h['node']['score'] *= stats_h['node']['weight'] if stats_h['node']['weight']
        stats_h['node']['score'] = Float( stats_h['node']['score'] )

        stats_h
    end

    # @return   [String]    contents of the log file
    def log
        IO.read prep_logging
    end

    # @return   [Hash]   the server's proc info
    def proc_info
        proc( Process.pid ).merge( 'node' => @node.info )
    end

    private

    def self._handlers
        @handlers ||= nil
        return @handlers if @handlers

        @handlers = Component::Manager.new( HANDLER_LIB, HANDLER_NAMESPACE )
        @handlers.load_all
        @handlers
    end

    def _handlers
        self.class._handlers
    end

    def resource_consumption_score
        cpu = mem = 0.0
        jobs.each do |job|
            mem += Float( job['proc']['pctmem'] ) if job['proc']['pctmem']
            cpu += Float( job['proc']['pctcpu'] ) if job['proc']['pctcpu']
        end
        cpu + mem
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
    end

    def shutdown
        print_status 'Shutting down...'
        @server.shutdown
    end

    def add_instance_to_pool
        owner = 'dispatcher'
        exception_jail {

            # get an available port for the child
            port  = avail_port
            token = generate_token

            pid = ::EM.fork_reactor {
                @opts.rpc_port = port
                Server::Instance.new( @opts, token )
            }

            print_status "Instance added to pool -- PID: #{pid} - " +
                "Port: #{@opts.rpc_port} - Owner: #{owner}"

            @pool << {
                'token'     => token,
                'pid'       => pid,
                'port'      => port,
                'url'       => "#{@opts.rpc_address}:#{port}",
                'owner'     => owner,
                'birthdate' => Time.now
            }

            @consumed_pids << pid

            # let the child go about its business
            Process.detach( pid )
        }
    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file( @opts.dir['logs'] +
            "/Dispatcher - #{Process.pid}-#{@opts.rpc_port}.log" )
    end

    def proc( pid )
        struct_to_h( ProcTable.ps( pid ) )
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

    #
    # Returns a random available port
    #
    # @return   Fixnum  port number
    #
    def avail_port
        nil while !avail_port?( port = rand_port )
        port
    end

    #
    # Returns a random port
    #
    def rand_port
        first, last = @opts.rpc_instance_port_range
        range = (first..last).to_a

        range[ rand( range.last - range.first ) ]
    end

    def generate_token
        secret = ''
        1000.times { secret << rand( 1000 ).to_s }
        Digest::MD5.hexdigest( secret )
    end

    #
    # Checks whether the port number is available
    #
    # @param    [Fixnum]  port
    #
    # @return   [Bool]
    #
    def avail_port?( port )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( '127.0.0.1', port ) )
            socket.close
            true
        rescue
            false
        end
    end

end

end
end
end
