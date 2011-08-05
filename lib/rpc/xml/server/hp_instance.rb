=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'webrick'
require 'webrick/https'
require 'xmlrpc/server'
require 'openssl'

module Arachni

require Options.instance.dir['lib'] + 'rpc/xml/client/instance'
require Options.instance.dir['lib'] + 'rpc/xml/client/dispatcher'

require Options.instance.dir['lib'] + 'rpc/xml/server/base'
require Options.instance.dir['lib'] + 'rpc/xml/server/output'
require Options.instance.dir['lib'] + 'rpc/xml/server/framework'
require Options.instance.dir['lib'] + 'rpc/xml/server/hp_instance/framework'
require Options.instance.dir['lib'] + 'rpc/xml/server/options'

module RPC
module XML
module Server

#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HPInstance < Base

    # the output interface for XML-RPC
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    private :shutdown, :alive?
    public  :shutdown, :alive?

    #
    # Initializes the XML-RPC interface, the HTTP(S) server and the framework.
    #
    # @param    [Options]    opts
    #
    def initialize( opts, token )

        prep_framework
        banner

        @opts = opts
        super( @opts, token )

        if @opts.debug
            debug!
        end


        if @opts.reroute_to_logfile
            reroute_to_file( @opts.dir['root'] +
                "logs/XMLRPC-Server - #{Process.pid}:#{@opts.rpc_port} - #{Time.now.asctime}.log" )
        else
            reroute_to_file( false )
        end

        set_handlers

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { shutdown }
        trap( 'INT' ) { shutdown }
    end

    #
    # Flushes the output buffer and returns all pending system messages.
    #
    # All messages are classified based on their type.
    #
    # @return   [Array<Hash>]
    #
    def output
        flush_buffer( )
    end

    #
    # Makes the HTTP(S) server go bye-bye...Lights out!
    #
    def shutdown
        print_status( 'Shutting down...' )
        super
        print_status( 'Done.' )
        return true
    end
    alias :shutdown! :shutdown

    #
    # Starts the HTTPS server and the XML-RPC service.
    #
    def run

        begin
            print_status( 'Starting the server...' )
            # start the show!
            super
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end
    end

    private

    def dispatcher
        @dispatcher ||=
            Arachni::RPC::XML::Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    #
    # Initialises the RPC framework.
    #
    def prep_framework
        pp @opts
        @framework = Arachni::RPC::XML::Server::HighPerformance::Framework.new( Options.instance )
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
    # Starts the XML-RPC service and attaches it to the HTTP(S) server.<br/>
    # It also prepares all the RPC handlers.
    #
    def set_handlers
        @service.clear_handlers
        add_handler( "service",   self )
        add_handler( "framework", @framework )
        add_handler( "opts",      @framework.framework.opts )
        add_handler( "modules",   @framework.modules )
        add_handler( "plugins",   @framework.plugins )
    end

end

end
end
end
end
