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
module RPC
module XML
module Server

#
# Dispatcher class
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base

    def initialize( opts )

        pkey = ::OpenSSL::PKey::RSA.new( File.read( opts.ssl_pkey ) )         if opts.ssl_pkey
        cert = ::OpenSSL::X509::Certificate.new( File.read( opts.ssl_cert ) ) if opts.ssl_cert

        if opts.ssl_pkey || opts.ssl_cert || opts.ssl_ca
            verification = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        else
            verification = ::OpenSSL::SSL::VERIFY_NONE
        end

        @server = ::WEBrick::HTTPServer.new(
            :Port            => opts.rpc_port,
            :SSLEnable       => opts.ssl  || false,
            :SSLVerifyClient => verification,
            :SSLCertName     => [ [ "CN", ::WEBrick::Utils::getservername ] ],
            :SSLCertificate  => cert,
            :SSLPrivateKey   => pkey,
            :SSLCACertificateFile => opts.ssl_ca
        )

        print_status( 'Initing XMLRPC Server...' )
        @service = ::XMLRPC::WEBrickServlet.new(  )
        @service.add_introspection
        @server.mount( "/RPC2", @service )
    end

    def add_handler( name, klass )
        @service.add_handler( ::XMLRPC::iPIMethods( name ), klass )
    end

    def run
        @server.start
    end

    def alive?
        return true
    end
    alias :is_alive :alive?

    def shutdown
        @server.shutdown
    end

    private

    def remove_nils( hash )
        hash.each_pair {
            |k, v|
            hash[k] = '' if v.nil?
            hash[k] = remove_nils( v ) if v.is_a? Hash
        }

        return hash
    end

end

end
end
end
end
