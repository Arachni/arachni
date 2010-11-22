=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'webrick'
require 'webrick/https'
require 'xmlrpc/server'
require 'openssl'

module Arachni

require Options.instance.dir['lib'] + 'ui/xmlrpcd/output'
require Options.instance.dir['lib'] + 'ui/xmlrpcd/rpc/framework'
require Options.instance.dir['lib'] + 'ui/xmlrpcd/rpc/options'

module UI

#
# Arachni::UI:XMLRPCD class
#
# Provides an XML-RPC server to assist with general integration and UI development.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class XMLRPCD

    # the output interface for XML-RPC
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    # Initializes the XML-RPC interface, the HTTP(S) server and the framework.
    #
    # @param    [Options]    opts
    #
    def initialize( opts )

        prep_framework
        banner

        if opts.help
            print_help
            exit 0
        end

        pkey = ::OpenSSL::PKey::RSA.new( File.read( opts.ssl_pkey ) )         if opts.ssl_pkey
        cert = ::OpenSSL::X509::Certificate.new( File.read( opts.ssl_cert ) ) if opts.ssl_cert

        @server = ::WEBrick::HTTPServer.new(
            :Port            => opts.rpc_port || 1337,
            :SSLEnable       => opts.ssl      || false,
            :SSLVerifyClient => ::OpenSSL::SSL::VERIFY_NONE,
            :SSLCertName     => [ [ "CN", ::WEBrick::Utils::getservername ] ],
            :SSLCertificate  => cert,
            :SSLPrivateKey   => pkey,
            :SSLCACertificateFile => opts.ssl_ca
        )

        # debug!

        set_handlers

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { @server.shutdown }
        trap( 'INT' ) { @server.shutdown }

    end

    #
    # Resets the framework leaving it lemon fresh for the next scan.
    #
    # If you reuse without reseting, Arachni will eat your kitten!<br/>
    # (And I don't mean sexually...)
    #
    def reset
        exception_jail {
            @framework.modules.clear
            Arachni.reset
            Arachni::Options.instance.reset
            Arachni::Options.instance.link_count_limit = nil
            prep_framework
            set_handlers
            output
        }
        return true
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
        @server.shutdown
    end

    #
    # Starts the HTTP(S) server and the XML-RPC service.
    #
    def run( )

        begin
            # start the show!
            @server.start
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end
    end

    private

    #
    # Initialises the RPC framework.
    #
    def prep_framework
        @framework = nil
        @framework = Arachni::UI::RPCD::Framework.new( Options.instance )
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

    def print_help
        puts <<USAGE
  Usage:  arachni_xmlrpc.rb \[options\]

  Supported options:

    -h
    --help                      output this

    --port                      specify port to listen to

    --ssl                       use SSL?
    --ssl_pkey   <file>         location of the SSL private key (.key)
    --ssl_cert   <file>         location of the SSL certificate (.cert)
    --ssl_ca     <file>         location of the CA file (.cert)

USAGE
    end

    #
    # Starts the XML-RPC service and attaches it to the HTTP(S) server.<br/>
    # It also prepares all the RPC handlers.
    #
    def set_handlers
        @service = ::XMLRPC::WEBrickServlet.new(  )
        @service.add_introspection
        @server.mount( "/RPC2", @service )
        @service.clear_handlers
        @service.add_handler( ::XMLRPC::iPIMethods( "service" ), self )
        @service.add_handler( ::XMLRPC::iPIMethods( "framework" ), @framework )
        @service.add_handler( ::XMLRPC::iPIMethods( "opts" ), @framework.opts )
        @service.add_handler( ::XMLRPC::iPIMethods( "modules" ), @framework.modules )
        @service.add_handler( ::XMLRPC::iPIMethods( "plugins" ), @framework.plugins )
    end

end

end
end
