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

        @framework = Arachni::UI::RPC::Framework.new( opts  )

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

        set_handlers

        trap( 'HUP' ) { @server.shutdown }
        trap( 'INT' ) { @server.shutdown }
        # ap @framework.methods


        # ap @framework.lsmod
        # Arachni.reset
        # @framework.modules.load( '*' )
    end

    def reset
        Arachni.reset
        @framework = nil
        @framework = Arachni::UI::RPC::Framework.new( Options.instance  )
        set_handlers
        return true
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
            @server.start
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end
    end

    private

    #
    # Outputs Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
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

    def set_handlers
        @service = ::XMLRPC::WEBrickServlet.new
        @service.add_introspection
        @server.mount( "/RPC2", @service )
        @service.clear_handlers
        @service.add_handler( ::XMLRPC::iPIMethods( "service" ), self )
        @service.add_handler( ::XMLRPC::iPIMethods( "opts" ), @framework.opts )
        @service.add_handler( ::XMLRPC::iPIMethods( "modules" ), @framework.modules )
        @service.add_handler( ::XMLRPC::iPIMethods( "framework" ), @framework )
    end

end

end
end
