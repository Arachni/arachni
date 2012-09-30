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

module Arachni

require Options.dir['lib'] + 'rpc/client/instance'
require Options.dir['lib'] + 'rpc/client/dispatcher'

require Options.dir['lib'] + 'rpc/server/base'
require Options.dir['lib'] + 'rpc/server/output'
require Options.dir['lib'] + 'rpc/server/framework'

module RPC
class Server

#
# RPC Server class
#
# Provides an RPC server to assist with general integration and UI development.
#
# Only instantiated by the Dispatcher to provide support for multiple
# and concurrent RPC clients/scans.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Instance
    include UI::Output
    include Utilities

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

        @server.logger.level = @opts.datastore[:log_level] if @opts.datastore[:log_level]

        @opts.datastore[:token] = token

        debug if @opts.debug

        if @opts.reroute_to_logfile
            reroute_to_file( @opts.dir['logs'] +
                "/Instance - #{Process.pid}-#{@opts.rpc_port}.log" )
        else
            reroute_to_file( false )
        end

        set_handlers

        # trap interrupts and exit cleanly when required
        %w(QUIT INT).each do |signal|
            trap( signal ){ shutdown } if Signal.list.has_key?( signal )
        end

        run
    end

    #
    # Flushes the output buffer and returns all pending system messages.
    #
    # All messages are classified based on their type.
    #
    # @return   [Array<Hash>]
    #
    def output( &block )
        @framework.output( &block )
    end

    #
    # Makes the server go bye-bye...Lights out!
    #
    def shutdown
        print_status( 'Shutting down...' )

        t = []
        @framework.instance_eval {
            @instances.each do |instance|
                # Don't know why but this works better than EM's stuff
                t << Thread.new { connect_to_instance( instance ).service.shutdown! }
            end
        }
        t.join

        @server.shutdown
        true
    end
    alias :shutdown! :shutdown

    def alive?
        @server.alive?
    end

    private

    #
    # Starts the HTTPS server and the RPC service.
    #
    def run
        print_status( 'Starting the server...' )
        # start the show!
        @server.run
    end

    def dispatcher
        @dispatcher ||=
            Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    #
    # Initialises the RPC framework.
    #
    def prep_framework
        @framework = Server::Framework.new( Options.instance )
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

    #
    # Starts the RPC service and attaches it to the HTTP(S) server.<br/>
    # It also prepares all the RPC handlers.
    #
    def set_handlers
        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        end

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
