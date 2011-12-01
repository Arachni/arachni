=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'rpc/client/instance'
require Options.instance.dir['lib'] + 'rpc/client/dispatcher'

require Options.instance.dir['lib'] + 'rpc/server/base'
require Options.instance.dir['lib'] + 'rpc/server/output'
require Options.instance.dir['lib'] + 'rpc/server/options'

require Options.instance.dir['lib'] + 'rpc/server/framework'

module RPC
class Server

#
# RPC Server class
#
# Provides an RPC server to assist with general integration and UI development.
#
# Only instantiated by the Dispatcher to provide support for multiple
# and concurent RPC clients/scans.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
class Instance

    # the output interface for RPC
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    # Initializes the RPC interface, the HTTP(S) server and the framework.
    #
    # @param    [Options]    opts
    #
    def initialize( opts, token )

        prep_framework
        banner

        @opts  = opts
        @token = token
        @server = Base.new( @opts, token )

        @opts.datastore[:token] = token

        if @opts.debug
            debug!
        end


        if logfile = @opts.reroute_to_logfile
            reroute_to_file( @opts.dir['logs'] +
                "Instance - #{Process.pid}-#{@opts.rpc_port}.log" )
        else
            reroute_to_file( false )
        end

        set_handlers

        # trap interrupts and exit cleanly when required
        [ 'QUIT', 'HUP', 'INT' ].each {
            |signal|
            trap( signal ){ shutdown } if Signal.list.has_key?( signal )
        }
    end

    #
    # Flushes the output buffer and returns all pending system messages.
    #
    # All messages are classified based on their type.
    #
    # @return   [Array<Hash>]
    #
    def output( &block )
        @framework.output {
            |out|
            block.call( out | flush_buffer )
        }
    end

    #
    # Makes the server go bye-bye...Lights out!
    #
    def shutdown
        print_status( 'Shutting down...' )

        t = []
        @framework.instances.each {
            |instance|
            # Don't know why but this works better than EM's stuff
            t << Thread.new {
                @framework.connect_to_instance( instance ).service.shutdown!
            }
        }

        t.join

        @server.shutdown
        return true
    end
    alias :shutdown! :shutdown

    #
    # Starts the HTTPS server and the RPC service.
    #
    def run
        print_status( 'Starting the server...' )
        # start the show!
        @server.run
    end

    def alive?
        @server.alive?
    end

    private

    def dispatcher
        @dispatcher ||=
            Arachni::RPC::Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    #
    # Initialises the RPC framework.
    #
    def prep_framework
        @framework = nil
        @framework = Arachni::RPC::Server::Framework.new( Options.instance )
    end

    #
    # Outputs the Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    def banner

        puts 'Arachni - Web Application Security Scanner Framework v' +
            @framework.version + ' [' + @framework.revision + ']
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
        puts
        puts

    end

    #
    # Starts the RPC service and attaches it to the HTTP(S) server.<br/>
    # It also prepares all the RPC handlers.
    #
    def set_handlers
        @server.add_async_check {
            |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        }

        @server.add_handler( "service",   self )
        @server.add_handler( "framework", @framework )
        @server.add_handler( "opts",      @framework.opts )
        @server.add_handler( "modules",   @framework.modules )
        @server.add_handler( "plugins",   @framework.plugins )
    end

end

end
end
end
