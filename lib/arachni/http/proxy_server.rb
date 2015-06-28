=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'webrick/httpproxy'
require 'webrick/https'

module Arachni
module HTTP

# We add our own type of WEBrick::HTTPProxyServer class that does not restrict
# header exchange and supports SSL interception.
#
# SSL interception is achieved by redirecting traffic via a 2nd (SSL enabled)
# instance of this server by hijacking the browser's CONNECT request.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class ProxyServer < WEBrick::HTTPProxyServer

    CACHE = {
        format_field_name: Support::Cache::RandomReplacement.new( 100 )
    }

    SKIP_HEADERS = Set.new( HopByHop | ['content-encoding'] )

    INTERCEPTOR_CA_CERTIFICATE =
        File.dirname( __FILE__ ) + '/proxy_server/ssl-interceptor-cacert.pem'

    INTERCEPTOR_CA_KEY =
        File.dirname( __FILE__ ) + '/proxy_server/ssl-interceptor-cakey.pem'

    # @param   [Hash]  options
    # @option options   [String]    :address    ('0.0.0.0')
    #   Address to bind to.
    # @option options   [Integer]    :port
    #   Port number to listen on -- defaults to a random port.
    # @option options   [Integer]    :timeout
    #   HTTP time-out for each request in milliseconds.
    # @option options   [Integer]    :concurrency   (OptionGroups::HTTP#request_concurrency)
    #   Maximum number of concurrent connections.
    # @option options   [Block]    :response_handler
    #   Block to be called to handle each response as it arrives -- will be
    #   passed the request and response.
    # @option options   [Block]    :request_handler
    #   Block to be called to handle each request as it arrives -- will be
    #   passed the request and response.
    # @option options   [String]    :ssl_certificate
    #   SSL certificate.
    # @option options   [String]    :ssl_private_key
    #   SSL private key.
    def initialize( options = {} )
        @options = {
            address:              '0.0.0.0',
            port:                 Utilities.available_port,
            ssl_certificate_name: [ [ 'CN', 'Arachni' ] ]
        }.merge( options )

        @logger = WEBrick::Log.new( Arachni.null_device, 7 )
        # Will force the proxy to stfu.
        @logger.close

        super(
            BindAddress:        @options[:address],
            Port:               @options[:port],
            MaxClients:         @options[:concurrency] || Options.http.request_concurrency,
            ProxyVia:           false,
            DoNotReverseLookup: true,
            AccessLog:          [],
            Logger:             @logger,
            Timeout:            @options[:timeout],
            SSLEnable:          @options.include?( :ssl_certificate ) &&
                                    @options.include?( :ssl_private_key ),
            SSLCertName:        @options[:ssl_certificate_name],
            SSLCertificate:     @options[:ssl_certificate],
            SSLPrivateKey:      @options[:ssl_private_key]
        )
    end

    # Starts the server without blocking, it'll only block until the server is
    # up and running and ready to accept connections.
    def start_async
        Thread.new { start }
        sleep 0.1 while !running?
        nil
    end

    # @return   [Bool]
    #   `true` if the server is running, `false` otherwise.
    def running?
        @status == :Running
    end

    # @return   [String]    Proxy server URL.
    def address
        "#{@options[:address]}:#{@options[:port]}"
    end

    # @return   [Bool]
    #   `true` if the proxy has active connections, `false` otherwise.
    def has_connections?
        active_connections != 0
    end

    # @return   [Integer]
    #   Amount of active connections.
    def active_connections
        @tokens.max - @tokens.size
    end

    private

    # Performs a GET request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    def do_GET( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Request.new( http_opts( url: url, headers: header ) )
        end
    end

    # Performs a POST request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    def do_POST( req, res )
        perform_proxy_request( req, res ) do |url, header|
            # Don't use the original request's Content-Length, let the HTTP
            # client handle it.
            header.delete 'Content-Length'

            Request.new( http_opts(
                             url:     url,
                             method:  :post,
                             body:    req.body,
                             headers: header
                         )
            )
        end
    end

    # Performs a PUT request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    def do_PUT( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Request.new( http_opts( url: url, method: :put, headers: header ) )
        end
    end

    # Performs a DELETE request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    def do_DELETE( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Request.new( http_opts( url: url, method: :delete, headers: header ) )
        end
    end

    # Performs a HEAD request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    def do_HEAD( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Request.new( http_opts( url: url, method: :head, headers: header ) )
        end
    end

    # Hijacks CONNECT requests and redirects them to our SSL interceptor proxy
    # which listens on {#interceptor_port}.
    #
    # @see #service
    # @see Webrick::HTTPProxyServer#service
    def do_CONNECT( req, res )
        host = req.unparsed_uri.split(':').first

        req.instance_variable_set( :@unparsed_uri, "127.0.0.1:#{interceptor_port}" )

        start_ssl_interceptor( host )

        super( req, res )
    end

    # @param    [Hash]  options
    #   Merges the given HTTP options with some default ones.
    def http_opts( options = {} )
        options.merge(
            performer:         self,

            # Don't follow redirects, the client should handle this.
            follow_location:   false,

            # Set the HTTP request timeout.
            timeout:           @options[:timeout],

            # Update the framework-wide cookie-jar with the transmitted cookies.
            update_cookies:    true,

            # We perform the request in blocking mode, parallelism is up to the
            # proxy client.
            mode:              :sync,

            # Don't limit the response size when using the proxy.
            response_max_size: -1
        )
    end

    # Starts the SSL interceptor proxy server.
    #
    # The interceptor will listen on {#interceptor_port}.
    def start_ssl_interceptor( host )
        return @interceptor if @interceptor

        ca     = OpenSSL::X509::Certificate.new( File.read( INTERCEPTOR_CA_CERTIFICATE ) )
        ca_key = OpenSSL::PKey::RSA.new( File.read( INTERCEPTOR_CA_KEY ) )

        keypair = OpenSSL::PKey::RSA.new( 4096 )

        req            = OpenSSL::X509::Request.new
        req.version    = 0
        req.subject    = OpenSSL::X509::Name.parse(
            "CN=#{host}/subjectAltName=#{host}/O=Arachni/OU=Proxy/L=Athens/ST=Attika/C=GR"
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

        # The interceptor is only used for SSL decryption/encryption, the actual
        # proxy functionality is forwarded to the plain proxy server.
        @interceptor = self.class.new(
            address:        '127.0.0.1',
            port:            interceptor_port,
            ssl_certificate: cert,
            ssl_private_key: keypair,
            service_handler: method( :proxy_service )
        )

        def @interceptor.service( request, response )
            @options[:service_handler].call( request, response )
        end

        @interceptor.start_async
    end

    # @return    [Integer]
    #   Picks and stores an available port number for the interceptor.
    def interceptor_port
        @interceptor_port ||= Utilities.available_port
    end

    # Communicates with the endpoint webapp and forwards its responses to the
    # proxy which then sends it to the browser.
    def perform_proxy_request( req, res )
        request  = yield( req.request_uri.to_s, setup_proxy_header( req, res ) )
        response = nil

        request.headers_string = "#{req.request_line}#{req.raw_header.join}"
        request.effective_body = req.body

        if @options[:request_handler]
            # Provisional empty, response in case the request_handler wants us to
            # skip performing the request.
            response = Response.new( url: req.request_uri.to_s )
            response.request = request

            # If the handler returns false then don't perform the HTTP request.
            if @options[:request_handler].call( request, response )
                # Even though it's a blocking request, force it to go through
                # the HTTP::Client in order to handle cookie update and
                # fingerprinting handlers.
                HTTP::Client.queue( request )
                response = request.run
            end
        else
            HTTP::Client.queue( request )
            response = request.run
        end

        if @options[:response_handler]
            @options[:response_handler].call( request, response )
        end

        # Disable persistent connections since they're not supported by the
        # server.
        res['proxy-connection'] = 'close'
        res['connection']       = 'close'

        # Convert Arachni::HTTP::Response to WEBrick::HTTPResponse.
        res.status = response.code.to_i

        choose_header( response.headers, res )

        # Scrub the existing cookies clean and pass the new ones.
        response.headers.set_cookie.each { |c| res.cookies << c }
        res.header.delete( 'set-cookie' )

        res.header['content-length'] = response.body.bytesize.to_s
        res.body = response.body
    end

    # Transfers headers from the webapp HTTP response to the Proxy HTTP response.
    #
    # @param    [#[], #each]    src
    #   Headers of the webapp response.
    # @param    [#[]=]    dst
    #   Headers of the forwarded/proxy response.
    def choose_header( src, dst )
        connections = Set.new( split_field( [src['connection']].flatten.first ) )

        src.each do |key, value|
            key = key.downcase
            next if SKIP_HEADERS.include?( key ) || connections.include?( key )

            dst[self.class.format_field_name( key )] = value
        end
    end

    def self.format_field_name( field )
        CACHE[:format_field_name][field] ||=
            field.split( /_|-/ ).map( &:capitalize ).join( '-' )
    end

end
end
end
