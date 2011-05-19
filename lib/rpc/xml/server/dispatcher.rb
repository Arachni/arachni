=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'socket'
require 'sys/proctable'

module Arachni

require Options.instance.dir['lib'] + 'rpc/xml/server/base'
require Options.instance.dir['lib'] + 'rpc/xml/server/instance'
require Options.instance.dir['lib'] + 'rpc/xml/server/output'

module RPC
module XML
module Server

#
# Dispatcher class
#
# Dispatches XML-RPC servers on demand providing a centralised environment
# for multiple XMLRPC clients and allows for extensive process monitoring.
#
# The process goes something like this:
#   * a client issues a 'dispatch' call
#   * the dispatcher starts a new XMLRPC server on a random port
#   * the dispatcher returns the port of the XMLRPC server to the client
#   * the client connects to the XMLRPC server listening on that port and does his business
#
# Once the client finishes using the XMLRPC server it *must* shut it down.<br/>
# If it doesn't the system will be eaten away by idle instances of XMLRPC servers.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
#
class Dispatcher < Base

    include Arachni::Module::Utilities
    include Arachni::UI::Output
    include ::Sys

    private :shutdown, :alive?
    public  :shutdown, :alive?

    def initialize( opts )

        banner

        @opts = opts
        @opts.rpc_port  ||= 7331
        @opts.pool_size ||= 5

        if opts.help
            print_help
            exit 0
        end

        super( @opts )

        prep_logging

        print_status( 'Initing XMLRPC Server...' )

        add_handler( "dispatcher", self )

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { shutdown }
        trap( 'INT' ) { shutdown }

        @jobs = []
        @pool = Queue.new

        print_status( 'Warming up the pool...' )
        prep_pool
        print_status( 'Done.' )

        print_status( 'Initialization complete.' )

    end

    # Starts the dispatcher's server
    def run
        print_status( 'Starting the server...' )
        super
    end

    def shutdown
        print_status( 'Shutting down...' )
        super
        print_status( 'Done.' )
    end

    #
    # Dispatches an XMLRPC server instance from the pool
    #
    # @param    [String]    owner   an owner assign to the dispatched XMLRPC server
    #
    # @return   [Hash]      includes port number, owner, clock info and proc info
    #
    def dispatch( owner = 'unknown' )

        # just to make sure...
        owner = owner.to_s
        cjob  = @pool.pop
        cjob['owner']     = owner
        cjob['starttime'] = Time.now

        print_status( "Server dispatched -- PID: #{cjob['pid']} - " +
            "Port: #{cjob['port']} - Owner: #{cjob['owner']}" )

        prep_pool

        @jobs << cjob

        return job( cjob['pid'] )
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

                return remove_nils( cjob )
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

        return {
            'running_jobs'    => running,
            'finished_jobs'   => finished,
            'init_pool_size'  => @opts.pool_size,
            'curr_pool_size'  => @pool.size
        }
    end

    #
    # Outputs the Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    def banner

        puts 'Arachni - Web Application Security Scanner Framework
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
        puts
        puts

    end

    def print_help
        puts <<USAGE
  Usage:  arachni_xmlrpcd \[options\]

  Supported options:

    -h
    --help                      output this

    --port                      specify port to listen to
                                    (Default: #{@opts.rpc_port})

    --reroute-to-logfile        reroute all output to a logfile under 'logs/'

    --pool-size                 how many server workers/processes should be available
                                  at any given moment (Default: #{@opts.pool_size})

    --debug


    SSL --------------------------

    (All SSL options will be honored by the dispatched XMLRPC instances as well.)
    (Do *not* use encrypted keys!)

    --ssl-pkey   <file>         location of the SSL private key (.pem)
                                    (Used to verify the server to the clients.)

    --ssl-cert   <file>         location of the SSL certificate (.pem)
                                    (Used to verify the server to the clients.)

    --ssl-ca     <file>         location of the CA certificate (.pem)
                                    (Used to verify the clients to the server.)
USAGE
    end


    private

    #
    # Initializes and updates the pool making sure that the number of
    # available server processes stays constant for any given moment
    #
    def prep_pool

        owner = 'dispatcher'

        (@pool.size - @opts.pool_size).abs.times {
            exception_jail{

                # get an available port for the child
                @opts.rpc_port = avail_port( )
                @token         = secret()

                pid = Kernel.fork {
                    exception_jail {
                        server = Arachni::RPC::XML::Server::Instance.new( @opts, @token )
                        trap( "INT", "IGNORE" )
                        server.run
                    }

                    # restore logging
                    reroute_to_file( @logfile )

                    print_status( "Server shutdown   -- PID: #{Process.pid} - " +
                        "Port: #{@opts.rpc_port}" )
                }

                print_status( "Server added to pool -- PID: #{pid} - " +
                    "Port: #{@opts.rpc_port} - Owner: #{owner}" )

                @pool << {
                    'token' => @token,
                    'pid'   => pid,
                    'port'  => @opts.rpc_port,
                    'owner' => owner,
                    'birthdate' => Time.now
                }

                # let the child go about his business
                Process.detach( pid )
                @token = nil
            }
        }

    end

    def prep_logging
        # reroute all output to a logfile
        @logfile ||= reroute_to_file( @opts.dir['root'] +
            "logs/XMLRPC-Dispatcher - #{Process.pid}:#{@opts.rpc_port} - #{Time.now.asctime}.log" )
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
        range = (1025..65535).to_a
        range[ rand( 65535 - 1025 ) ]
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
end
