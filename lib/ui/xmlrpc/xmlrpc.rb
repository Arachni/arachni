=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'xmlrpc/server'

module Arachni

require Options.instance.dir['lib'] + 'ui/xmlrpc/output'
require Options.instance.dir['lib'] + 'ui/xmlrpc/rpc/framework'

module UI

#
# Arachni::UI:XMLRPC class
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
# @see Arachni::Framework
#
class XMLRPC

    #
    # Instance options
    #
    # @return    [Options]
    #
    attr_reader :opts

    # the output interface for CLI
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    # Initializes the command line interface and the framework
    #
    # @param    [Options]    opts
    #
    def initialize( opts )

        @server = ::XMLRPC::Server.new( 8585 )
        @framework = Arachni::UI::RPC::Framework.new( opts  )

        # ap @framework.methods
        set_handlers

        # ap @framework.lsmod
        # Arachni.reset
        # @framework.modules.load( '*' )

        @server.add_introspection
    end

    def reset
        Arachni.reset
        @framework = nil
        @framework = Arachni::UI::RPC::Framework.new( Options.instance  )
        set_handlers
        return true
    end

    def set_handlers
        @server.clear_handlers
        @server.add_handler( ::XMLRPC::iPIMethods( "service" ), self )
        @server.add_handler( ::XMLRPC::iPIMethods( "opts" ), @framework.opts )
        @server.add_handler( ::XMLRPC::iPIMethods( "modules" ), @framework.modules )
        @server.add_handler( ::XMLRPC::iPIMethods( "reports" ), @framework.reports )
        @server.add_handler( ::XMLRPC::iPIMethods( "framework" ), @framework )
    end

    def output
        flush_buffer( )
    end

    def shutdown
        @server.shutdown
    end

    #
    # Runs Arachni
    #
    def run( )

        begin
            # start the show!
            @server.serve
        rescue Arachni::Exceptions => e
            print_error( e.to_s )
            print_info( "Run arachni with the '-h' parameter for help." )
            print_line
            exit 0
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end
    end

end

end
end
