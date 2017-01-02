=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

lib = Options.paths.lib
require lib + 'processes/manager'
require lib + 'rpc/client'
require lib + 'rpc/server/base'
require lib + 'rpc/server/instance'
require lib + 'rpc/server/output'

module RPC
class Server

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
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Dispatcher
    require Options.paths.lib + 'rpc/server/dispatcher/node'
    require Options.paths.lib + 'rpc/server/dispatcher/service'

    include Utilities
    include UI::Output

    SERVICE_NAMESPACE = Service

    def initialize( options = Options.instance )
        @options = options

        @options.dispatcher.external_address ||= @options.rpc.server_address
        @options.snapshot.save_path          ||= @options.paths.snapshots

        @server = Base.new( @options )
        @server.logger.level = @options.datastore.log_level if @options.datastore.log_level

        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end

        @url = "#{@options.dispatcher.external_address}:#{@options.rpc.server_port}"

        # let the instances in the pool know who to ask for routing instructions
        # when we're in grid mode.
        @options.datastore.dispatcher_url = @url

        prep_logging

        print_status 'Starting the RPC Server...'

        @server.add_handler( 'dispatcher', self )

        # trap interrupts and exit cleanly when required
        trap_interrupts { shutdown }

        @jobs          = []
        @consumed_pids = []
        @pool          = Reactor.global.create_queue

        print_status "Populating the pool with #{@options.dispatcher.pool_size}  Instances."
        if @options.dispatcher.pool_size > 0
            @options.dispatcher.pool_size.times { add_instance_to_pool( false ) }
        end

        print_status 'Waiting for Instances to come on-line.'

        # Check up on the pool and start the server once it has been filled.
        Reactor.global.at_interval( 0.1 ) do |task|
            print_debug "Instances: #{@pool.size}/#{@options.dispatcher.pool_size}"
            next if @options.dispatcher.pool_size != @pool.size
            task.done

            print_status 'Instances are on-line.'

            _services.each do |name, service|
                @server.add_handler( name, service.new( @options, self ) )
            end

            @node = Node.new( @options, @logfile )
            @server.add_handler( 'node', @node )

            run
        end
    end

    def services
        _services.keys
    end

    # @return   [TrueClass]
    #   true
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

        Reactor.global.create_iterator( @node.neighbours ).map( each, after )
    end

    # Dispatches an {Instance} from the pool.
    #
    # @param    [String]  owner
    #   An owner to assign to the {Instance}.
    # @param    [Hash]    helpers
    #   Hash of helper data to be added to the job.
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
    def dispatch( owner = 'unknown', helpers = {}, load_balance = true, &block )
        if load_balance && @node.grid_member?
            preferred do |url|
                connect_to_peer( url ).dispatch( owner, helpers, false, &block )
            end
            return
        end

        if @options.dispatcher.pool_size <= 0
            block.call nil
            return
        end

        if @pool.empty?
            block.call false
        else
            @pool.pop do |cjob|
                cjob['owner']     = owner.to_s
                cjob['starttime'] = Time.now.to_s
                cjob['helpers']   = helpers

                print_status "Instance dispatched -- PID: #{cjob['pid']} - " +
                    "Port: #{cjob['port']} - Owner: #{cjob['owner']}"

                @jobs << cjob
                block.call cjob
            end
        end

        Reactor.global.schedule { add_instance_to_pool }
    end

    # Returns proc info for a given pid
    #
    # @param    [Fixnum]      pid
    #
    # @return   [Hash]
    def job( pid )
        @jobs.each do |j|
            next if j['pid'] != pid
            cjob = j.dup

            currtime = Time.now

            cjob['currtime'] = currtime.to_s
            cjob['age']      = currtime - Time.parse( cjob['birthdate'] )
            cjob['runtime']  = currtime - Time.parse( cjob['starttime'] )
            cjob['alive']    = Arachni::Processes::Manager.alive?( pid )

            return cjob
        end
    end

    # @return   [Array<Hash>]
    #   Returns info for all jobs.
    def jobs
        @jobs.map { |cjob| job( cjob['pid'] ) }.compact
    end

    # @return   [Array<Hash>]
    #   Returns info for all running jobs.
    #
    # @see #jobs
    def running_jobs
        jobs.select { |job| job['alive'] }
    end

    # @return   [Array<Hash>]
    #   Returns info for all finished jobs.
    #
    # @see #jobs
    def finished_jobs
        jobs.reject { |job| job['alive'] }
    end

    # @return   [Float]
    #   Workload score for this Dispatcher, calculated using the number
    #   of {#running_jobs} and the configured node weight.
    #
    #   Lower is better.
    def workload_score
        score = (running_jobs.size + 1).to_f
        score *= @node.info['weight'].to_f if @node.info['weight']
        score
    end

    # @return   [Hash]
    #   Returns server stats regarding the jobs and pool.
    def statistics
        stats_h = {
            'running_jobs'   => running_jobs,
            'finished_jobs'  => finished_jobs,
            'init_pool_size' => @options.dispatcher.pool_size,
            'curr_pool_size' => @pool.size,
            'consumed_pids'  => @consumed_pids,
            'snapshots'      => Dir.glob( "#{@options.snapshot.save_path}*.afs" )
        }

        stats_h.merge!( 'node' => @node.info, 'neighbours' => @node.neighbours )
        stats_h['node']['score']  = workload_score

        stats_h
    end

    # @return   [String]
    #   Contents of the log file
    def log
        IO.read prep_logging
    end

    # @private
    def pid
        Process.pid
    end

    private

    def self._services
        @services ||= nil
        return @services if @services

        @services = Component::Manager.new( Options.paths.services, SERVICE_NAMESPACE )
        @services.load_all
        @services
    end

    def _services
        self.class._services
    end

    def trap_interrupts( &block )
        %w(QUIT INT).each do |signal|
            trap( signal, &block || Proc.new{ } ) if Signal.list.has_key?( signal )
        end
    end

    # Starts the dispatcher's server
    def run
        Reactor.global.on_error do |_, e|
            print_error "Arachni::Reactor: #{e}"

            e.backtrace.each do |l|
                print_error "Arachni::Reactor: #{l}"
            end
        end

        print_status 'Ready'
        @server.start
    rescue => e
        print_exception e

        $stderr.puts "Could not start server, for details see: #{@logfile}"

        # If the server fails to start kill the pool Instances
        # to prevent zombie processes.
        @consumed_pids.each { |p| kill p }
        exit 1
    end

    def shutdown
        print_status 'Shutting down...'
        Arachni::Reactor.global.stop
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
        port  = Utilities.available_port
        token = Utilities.generate_token

        pid = Processes::Manager.spawn( :instance, port: port, token: token )
        Process.detach( pid )
        @consumed_pids << pid

        print_status "Instance added to pool -- PID: #{pid} - " +
            "Port: #{port} - Owner: #{owner}"

        # Wait until the Instance has booted before adding it to the pool.
        Client::Instance.when_ready( "#{@options.rpc.server_address}:#{port}", token ) do
            @operation_in_progress = false

            @pool << {
                'token'     => token,
                'pid'       => pid,
                'port'      => port,
                'url'       => "#{@options.dispatcher.external_address}:#{port}",
                'owner'     => owner,
                'birthdate' => Time.now.to_s
            }
        end
    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file( @options.paths.logs +
            "/Dispatcher - #{Process.pid}-#{@options.rpc.server_port}.log" )
    end

    def connect_to_peer( url )
        @rpc_clients ||= {}
        @rpc_clients[url] ||= Client::Dispatcher.new( @options, url )
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
