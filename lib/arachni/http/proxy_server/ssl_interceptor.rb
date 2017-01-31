=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP
class ProxyServer

class SSLInterceptor < Connection
    include Arachni::UI::Output
    personalize_output

    include TLS

    CA_CERTIFICATE = File.dirname( __FILE__ ) + '/ssl-interceptor-cacert.pem'
    CA_KEY         = File.dirname( __FILE__ ) + '/ssl-interceptor-cakey.pem'

    def initialize( options )
        super

        @origin_host = options[:origin_host]
    end

    def on_connect
        print_debug_level_3 'Connected, starting SSL handshake.'
        start_tls
    end

    def on_close( reason = nil )
        print_debug_level_3 "Closed because: [#{reason.class}] #{reason}"
        @parent.mark_connection_inactive self
    end

    def start_tls
        if @socket.is_a? OpenSSL::SSL::SSLSocket
            @ssl_context = @socket.context
            return
        end

        if @role == :server
            ca     = OpenSSL::X509::Certificate.new( File.read( CA_CERTIFICATE ) )
            ca_key = OpenSSL::PKey::RSA.new( File.read( CA_KEY ) )

            keypair = OpenSSL::PKey::RSA.new( 1024 )

            req            = OpenSSL::X509::Request.new
            req.version    = 0
            req.subject    = OpenSSL::X509::Name.parse(
                "CN=#{@origin_host}/subjectAltName=#{@origin_host}/O=Arachni/OU=Proxy/L=Athens/ST=Attika/C=GR"
            )
            req.public_key = keypair.public_key
            req.sign( keypair, OpenSSL::Digest::SHA1.new )

            cert            = OpenSSL::X509::Certificate.new
            cert.version    = 2
            cert.serial     = rand( 999999 )
            cert.not_before = Time.new
            cert.not_after  = cert.not_before + (60 * 60 * 24 * 365)
            cert.public_key = req.public_key
            cert.subject    = req.subject
            cert.issuer     = ca.subject

            ef = OpenSSL::X509::ExtensionFactory.new
            ef.subject_certificate = cert
            ef.issuer_certificate  = ca

            cert.extensions = [
                ef.create_extension( 'basicConstraints', 'CA:FALSE', true ),
                ef.create_extension( 'extendedKeyUsage', 'serverAuth', false ),
                ef.create_extension( 'subjectKeyIdentifier', 'hash' ),
                ef.create_extension( 'authorityKeyIdentifier', 'keyid:always,issuer:always' ),
                ef.create_extension( 'keyUsage',
                                     'nonRepudiation,digitalSignature,keyEncipherment,dataEncipherment',
                                     true
                )
            ]
            cert.sign( ca_key, OpenSSL::Digest::SHA1.new )

            @ssl_context = OpenSSL::SSL::SSLContext.new
            @ssl_context.cert = cert
            @ssl_context.key  = keypair

            @socket = OpenSSL::SSL::SSLServer.new( @socket, @ssl_context )
        else
            @socket = OpenSSL::SSL::SSLSocket.new( @socket, @ssl_context )
            @socket.sync_close = true

            # We've switched to SSL, a connection needs to be re-established
            # via the SSL handshake.
            @connected         = false
        end

        @socket
    end
end

end
end
end
