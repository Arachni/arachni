=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ProxyServer < WEBrick::HTTPProxyServer

    INTERCEPTOR_CERTIFICATE =
        File.dirname( __FILE__ ) + '/proxy_server/ssl-interceptor-cert.pem'

    INTERCEPTOR_PRIVATE_KEY =
        File.dirname( __FILE__ ) + '/proxy_server/ssl-interceptor-pkey.pem'

    # @param   [Hash]  options
    # @option options   [String]    :address    ('0.0.0.0')
    #   Address to bind to.
    # @option options   [Integer]    :port
    #   Port number to listen on -- defaults to a random port.
    # @option options   [Integer]    :timeout
    #   HTTP time-out for each request in milliseconds.
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

        super(
            BindAddress:         @options[:address],
            Port:                @options[:port],
            ProxyVia:            false,
            DoNotReverseLookup:  true,
            AccessLog:           [],
            Logger:              WEBrick::Log::new( '/dev/null', 7 ),
            Timeout:             @options[:timeout],
            SSLEnable:           @options.include?( :ssl_certificate ) &&
                                     @options.include?( :ssl_private_key ),
            SSLCertName:         @options[:ssl_certificate_name],
            SSLCertificate:      @options[:ssl_certificate],
            SSLPrivateKey:       @options[:ssl_private_key]
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

    # @return   [Integer]   Amount of active connections.
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
        req.instance_variable_set( :@unparsed_uri, "localhost:#{interceptor_port}" )
        start_ssl_interceptor
        super( req, res )
    end

    # @param    [Hash]  options
    #   Merges the given HTTP options with some default ones.
    def http_opts( options = {} )
        options.merge(
            # Don't use cookies from our own cookie-jar, let the client handle
            # it.
            no_cookiejar:    true,

            # Don't follow redirects, the client should handle this.
            follow_location: false,

            # Set the HTTP request timeout.
            timeout:         @options[:timeout],

            # Update the framework-wide cookie-jar with the transmitted cookies.
            update_cookies:  true,

            # We perform the request in blocking mode, parallelism is up to the
            # proxy client.
            mode:            :sync
        )
    end

    # Starts the SSL interceptor proxy server.
    #
    # The interceptor will listen on {#interceptor_port}.
    def start_ssl_interceptor
        return @interceptor if @interceptor

        # The interceptor is only used for SSL decryption/encryption, the actual
        # proxy functionality is forwarded to the plain proxy server.
        @interceptor = self.class.new(
            address:        'localhost',
            port:            interceptor_port,
            ssl_certificate:
                OpenSSL::X509::Certificate.new( File.read( INTERCEPTOR_CERTIFICATE ) ),
            ssl_private_key:
                OpenSSL::PKey::RSA.new( File.read( INTERCEPTOR_PRIVATE_KEY ) ),
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
        request = yield( req.request_uri.to_s, setup_proxy_header( req, res ) )

        # Provisional empty, response in case the request_handler wants us to
        # skip performing the request.
        response = Response.new( url: req.request_uri.to_s )
        response.request = request
        request.on_complete { |r| response = r }

        if @options[:request_handler]
            if @options[:request_handler].call( request, response )
                HTTP::Client.queue( request )
            end
        else
            HTTP::Client.queue( request )
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
    # @param    [#[], #each]    src     headers of the webapp response
    # @param    [#[]=]    dst     headers of the forwarded/proxy response
    def choose_header( src, dst )
        connections = split_field( [src['connection']].flatten.first )

        src.each do |key, value|
            key = key.downcase

            if HopByHop.member?( key )          || # RFC2616: 13.5.1
                connections.member?( key )      || # RFC2616: 14.10
                key == 'content-encoding'
                @logger.debug( "choose_header: `#{key}: #{value}'" )
                next
            end

            field = key.to_s.split( /_|-/ ).
                map { |segment| segment.capitalize }.join( '-' )
            dst[field] = value
        end
    end

end
end
end
