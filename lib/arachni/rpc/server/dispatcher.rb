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

require Options.instance.dir['lib'] + 'rpc/client/dispatcher'

require Options.instance.dir['lib'] + 'rpc/server/base'
require Options.instance.dir['lib'] + 'rpc/server/instance'
require Options.instance.dir['lib'] + 'rpc/server/output'

module RPC
class Server

#
# Dispatcher class
#
# Dispatches RPC servers on demand providing a centralized environment
# for multiple RPC clients and allows for extensive process monitoring.
#
# The process goes something like this:
#   * a client issues a 'dispatch' call
#   * the dispatcher starts a new RPC server on a random port
#   * the dispatcher returns the port of the RPC server to the client
#   * the client connects to the RPC server listening on that port and does his business
#
# Once the client finishes using the RPC server it *must* shut it down.<br/>
# If it doesn't the system will be eaten away by idle instances of RPC servers.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2
#
class Dispatcher

    require Options.instance.dir['lib'] + 'rpc/server/node'

    include Arachni::Module::Utilities
    include Arachni::UI::Output
    include ::Sys

    def initialize( opts )

        banner

        @opts = opts

        @opts.rpc_port     ||= 7331
        @opts.rpc_address  ||= 'localhost'
        @opts.pool_size    ||= 5

        if @opts.help
            print_help
            exit 0
        end

        @server = Base.new( @opts )

        @server.add_async_check {
            |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        }

        # let the instances in the pool know who to ask for routing instructions
        # when we're in grid mode.
        @opts.datastore[:dispatcher_url] = "#{@opts.rpc_address}:#{@opts.rpc_port.to_s}"

        prep_logging

        print_status( 'Initing RPC Server...' )

        @server.add_handler( "dispatcher", self )

        # trap interrupts and exit cleanly when required
        trap_interrupts { shutdown }

        @jobs = []
        @pool = Queue.new
        @replenisher = Queue.new

        print_status( 'Warming up the pool...' )
        @opts.pool_size.times{ add_instance_to_pool }

        # this thread will wait in the background and replenish the pool
        Thread.new {
            loop {
                add_instance_to_pool
                @replenisher.pop
            }
        }

        @node = nil

        print_status( 'Done.' )

        print_status( 'Initialization complete.' )

        run
    end

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
    def dispatch( owner = 'unknown', helpers = {} )

        # just to make sure...
        owner = owner.to_s
        cjob  = @pool.shift
        cjob['owner']     = owner
        cjob['starttime'] = Time.now
        cjob['helpers']   = helpers

        print_status( "Instance dispatched -- PID: #{cjob['pid']} - " +
            "Port: #{cjob['port']} - Owner: #{cjob['owner']}" )

        @replenisher << true

        @jobs << cjob

        return cjob
    end

    #
    # Returns proc info for a given pid
    #
    # @param    [Fixnum]      pid
    #
    # @return   [Hash]
    #
    def job( pid )
        @jobs.each {
            |i|
            cjob = i.dup
            if cjob['pid'] == pid
                cjob['currtime'] = Time.now
                cjob['age'] = cjob['currtime'] - cjob['birthdate']
                cjob['runtime']  = cjob['currtime'] - cjob['starttime']
                cjob['proc'] =  proc( cjob['pid'] )

                return cjob
            end
        }
    end

    #
    # Returns proc info for all jobs
    #
    # @return   [Array<Hash>]
    #
    def jobs
        jobs = []
        @jobs.each {
            |cjob|
            proc_info = job( cjob['pid'] )
            jobs << proc_info if proc_info
        }
        return jobs
    end

    #
    # Returns server stats regarding the jobs and pool
    #
    # @return   [Hash]
    #
    def stats
        cjobs    = jobs( )
        running  = cjobs.reject{ |job| job['proc'].empty? }
        finished = cjobs - running

        stats = {
            'running_jobs'    => running,
            'finished_jobs'   => finished,
            'init_pool_size'  => @opts.pool_size,
            'curr_pool_size'  => @pool.size
        }

        if @node
            stats.merge!( 'node' => @node.info, 'neighbours' => @node.neighbours )
        end

        return stats
    end

    def log
        IO.read( prep_logging )
    end

    def proc_info
        p = proc( Process.pid )

        if @node
            p.merge!( 'node' => @node.info )
        end

        return p
    end

    private

    #
    # Outputs the Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    def banner

        puts 'Arachni - Web Application Security Scanner Framework
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
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
        [ 'QUIT', 'INT' ].each {
            |signal|
            trap( signal, &block || Proc.new{ } ) if Signal.list.has_key?( signal )
        }
    end

    # Starts the dispatcher's server
    def run
        print_status( 'Starting the server...' )
        t = Thread.new { @server.run }

        # wait for the server to settle
        sleep( 0.1 ) while !@server.ready?

        @node = Node.new( @opts, @logfile )
        @server.add_handler( "node", @node )
        t.join
    end

    def shutdown
        print_status( 'Shutting down...' )
        @server.shutdown
    end

    def add_instance_to_pool

        owner = 'dispatcher'
        exception_jail{

            # get an available port for the child
            @opts.rpc_port = avail_port( )
            @token         = secret( )

            pid = ::EM.fork_reactor {
                exception_jail {
                    Arachni::RPC::Server::Instance.new( @opts, @token )
                }
            }

            print_status( "Instance added to pool -- PID: #{pid} - " +
                "Port: #{@opts.rpc_port} - Owner: #{owner}" )

            @pool << {
                'token' => @token,
                'pid'   => pid,
                'port'  => @opts.rpc_port,
                'url'   => "#{@opts.rpc_address}:#{@opts.rpc_port}",
                'owner' => owner,
                'birthdate' => Time.now
            }

            # let the child go about his business
            Process.detach( pid )
            @token = nil
        }

    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file( @opts.dir['logs'] +
            "Dispatcher - #{Process.pid}-#{@opts.rpc_port}.log" )
    end

    def proc( pid )
        struct_to_h( ProcTable.ps( pid ) )
    end

    def struct_to_h( struct )
        hash = {}

        return hash if !struct

        struct.each_pair {
            |k, v|
            v = v.to_s if v.is_a?( Bignum ) || v.is_a?( Fixnum )
            hash[k.to_s] = v
        }

        return hash
    end

    #
    # Returns a random available port
    #
    # @return   Fixnum  port number
    #
    def avail_port

        port = rand_port
        while !avail_port?( port )
            port = rand_port
        end

        return port
    end

    #
    # Returns a random port
    #
    def rand_port
        first, last = @opts.rpc_instance_port_range
        range = (first..last).to_a

        range[ rand( range.last - range.first ) ]
    end

    def secret
      secret = ''
      1000.times {
          secret += rand( 1000 ).to_s
      }

      return Digest::MD5.hexdigest( secret )
    end

    #
    # Checks whether the port number is available
    #
    # @param    Fixnum  port
    #
    # @return   Bool
    #
    def avail_port?( port )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( "127.0.0.1", port ) )
            socket.close
            return true
        rescue
            return false
        end
    end

end

end
end
end
