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
require Options.instance.dir['lib'] + 'rpc/xml/server/options'

require Options.instance.dir['lib'] + 'rpc/xml/server/high_performance/framework'

module RPC
module XML
module Server

#
# XMLRPC Server class
#
# Provides an XML-RPC server to assist with general integration and UI development.
#
# Only instantiated by the Dispatcher to provide support for multiple
# and concurent XMLRPC clients/scans.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
class Instance < Base

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

        @opts  = opts
        @token = token
        super( @opts, token )

        @opts.datastore[:token] = token

        if @opts.debug
            debug!
        end


        if logfile = @opts.reroute_to_logfile
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
        @framework.output | flush_buffer( )
    end

    #
    # Makes the HTTP(S) server go bye-bye...Lights out!
    #
    def shutdown
        @framework.instances.each {
            |instance|

            3.times {
                begin
                    instance.service.shutdown!
                    break
                rescue Exception => e
                    ap e
                    ap e.backtrace

                    instance.service.shutdown!
                end
            }
        }

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
        @framework = nil
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
        add_handler( "opts",      @framework.opts )
        add_handler( "modules",   @framework.modules )
        add_handler( "plugins",   @framework.plugins )
    end

end

end
end
end
end
