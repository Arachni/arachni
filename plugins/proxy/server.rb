=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'webrick/httpproxy'
require 'webrick/https'

class Arachni::Plugins::Proxy

#
# We add our own type of WEBrick::HTTPProxyServer class that supports
# notifications when the user tries to access a resource irrelevant
# to the scan, does not restrict header exchange and supports SSL interception.
#
# SSL interception is achieved by redirecting traffic to a 2nd (SSL enabled)
# instance of this server by hijacking the browser's CONNECT request.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server < WEBrick::HTTPProxyServer

    #
    # Transfers headers from the webapp HTTP response to the Proxy HTTP response.
    #
    # @param    [#[], #each]    src     headers of the webapp response
    # @param    [#[]=]    dst     headers of the forwarded/proxy response
    #
    def choose_header( src, dst )
        connections = split_field( [src['connection']].flatten.first )

        src.each do |key, value|
            key = key.downcase

            if HopByHop.member?( key )          || # RFC2616: 13.5.1
                connections.member?( key )      || # RFC2616: 14.10
                 #ShouldNotTransfer.member?(key)   # pragmatics
                key == 'content-encoding'
                @logger.debug( "choose_header: `#{key}: #{value}'" )
                next
            end

            field = key.to_s.split( /_|-/ ).map { |segment| segment.capitalize }.join( '-' )
            dst[field] = value
        end
    end

    #
    # Performs a GET request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    #
    def do_GET( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP::Client.get( url, http_opts( headers: header ) ).response
        end
    end

    #
    # Performs a POST request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    #
    def do_POST( req, res )
        perform_proxy_request( req, res ) do |url, header|
            params = Arachni::Utilities.form_parse_request_body( req.body )

            # This is not necessary since we've parsed and put the POST body
            # in the request parameters. Otherwise the server will not return
            # a response.
            header.delete 'Content-Length'

            Arachni::HTTP::Client.post( url, http_opts( parameters: params, headers: header ) ).response
        end
    end

    #
    # Performs a PUT request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    #
    def do_PUT( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP::Client.request( url, http_opts( method: :put, headers: header ) ).response
        end
    end

    #
    # Performs a DELETE request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    #
    def do_DELETE( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP::Client.request( url, http_opts( method: :delete, headers: header ) ).response
        end
    end

    #
    # Hijacks CONNECT requests and redirects them to our SSL interceptor proxy
    # which listens on {#interceptor_port}.
    #
    # @see #service
    # @see Webrick::HTTPProxyServer#service
    #
    def do_CONNECT( req, res )
        req.instance_variable_set( :@unparsed_uri, "localhost:#{interceptor_port}" )
        start_ssl_interceptor
        super( req, res )
    end

    #
    # Performs a HEAD request.
    #
    # @see Webrick::HTTPProxyServer#proxy_service
    #
    def do_HEAD( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP::Client.request( url, http_opts( method: :head, headers: header ) ).response
        end
    end

    # @param    [Hash]  opts    merges HTTP opts with some defaults
    def http_opts( opts = {} )
        opts.merge( no_cookiejar: true, mode: :sync, follow_location: false,
                    timeout: @config[:Timeout], update_cookies: true )
    end

    #
    # Starts the SSL interceptor proxy server.
    #
    # The interceptor will listen on {#interceptor_port}.
    #
    def start_ssl_interceptor
        return @interceptor if @interceptor

        dir = File.dirname( __FILE__ ) + '/'
        cert = OpenSSL::X509::Certificate.new( File.read( dir + 'ssl-interceptor-cert.pem' ) )
        pkey = OpenSSL::PKey::RSA.new( File.read( dir + 'ssl-interceptor-pkey.pem' ) )

        @interceptor = self.class.new(
            BindAddress:    'localhost',
            Port:           interceptor_port,
            SSLEnable:      true,
            SSLCertName:    [ [ 'CN', WEBrick::Utils::getservername ] ],
            SSLEnable:      true,
            SSLCertificate: cert,
            SSLPrivateKey:  pkey,
            ArachniProxy:   method( :proxy_service ),
            ProxyRequestHandler: @config[:ProxyRequestHandler],
            Logger:         WEBrick::Log::new( '/dev/null', 7 )
        )

        def @interceptor.service( req, res )
            @config[:ArachniProxy].call( req, res ) if @config[:ProxyRequestHandler].call( req, res )
        end

        Thread.new { @interceptor.start }
        sleep 1
        @interceptor
    end

    # @return    [Integer]   picks and stores an available port number for the interceptor
    def interceptor_port
        @interceptor_port ||= available_port
    end

    # @return    [Integer]   returns an available port number
    def available_port
        loop do
            port = 5555 + rand( 9999 )
            begin
                socket = Socket.new( :INET, :STREAM, 0 )
                socket.bind( Addrinfo.tcp( '127.0.0.1', port ) )
                socket.close
                return port
            rescue Errno::EADDRINUSE
            end
        end
    end

    # Communicates with the endpoint webapp and forwards its responses to the
    # proxy which then sends it to the browser.
    def perform_proxy_request( req, res )
        response = yield( req.request_uri.to_s, setup_proxy_header( req, res ) )

        # Disable persistent connections to simplify things.
        res['proxy-connection'] = 'close'
        res['connection']       = 'close'

        # Convert Arachni::HTTP::Response to WEBrick::HTTPResponse.

        res.status = response.code.to_i
        choose_header( response, res )

        # scrub the existing cookies clean and pass the new ones
        sc = response.headers['Set-Cookie']
        sc.each { |c| res.cookies << c } if sc.is_a?( Array )
        res.header.delete( 'set-cookie' )

        #set_cookie( response, res )
        set_via( res )

        res.header['content-length'] = response.body.size.to_s
        res.body = response.body
    end

end
end
