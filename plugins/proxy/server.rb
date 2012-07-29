=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# to the scan and does not restrict header exchange.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server < WEBrick::HTTPProxyServer

    def choose_header( src, dst )
        connections = split_field( src['connection'] )

        src.each do |key, value|
            key = key.downcase

            if HopByHop.member?( key )          || # RFC2616: 13.5.1
                connections.member?( key )       || # RFC2616: 14.10
                 #ShouldNotTransfer.member?(key)    # pragmatics
                key == 'content-encoding'
                @logger.debug( "choose_header: `#{key}: #{value}'" )
                next
            end

            dst[key.to_s.split(/_|-/).map { |segment| segment.capitalize }.join("-")] = value
        end
    end

    def do_GET( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP.get( url , http_opts( headers: header ) ).response
        end
    end

    def do_POST( req, res )
        perform_proxy_request( req, res ) do |url, header|
            params = Arachni::Utilities.parse_query( "?#{req.body}" )
            Arachni::HTTP.post( url, http_opts( params: params, headers: header ) ).response
        end
    end

    def do_CONNECT( req, res )
        req.instance_variable_set( :@unparsed_uri, "localhost:#{interceptor_port}" )
        start_ssl_interceptor
        super( req, res )
    end

    def do_HEAD( req, res )
        perform_proxy_request( req, res ) do |url, header|
            Arachni::HTTP.request( url , http_opts( method: :head, headers: header ) ).response
        end
    end

    def http_opts( opts = {} )
        opts.merge( no_cookiejar: true, async: false )
    end

    def start_ssl_interceptor
        return @interceptor if @interceptor

        dir = File.dirname( __FILE__ ) + '/'
        cert = OpenSSL::X509::Certificate.new( File.read( dir + 'ssl-interceptor-cert.pem' ) )
        pkey = OpenSSL::PKey::RSA.new( File.read( dir + 'ssl-interceptor-pkey.pem' ) )

        @interceptor = self.class.new(
            BindAddress:    'localhost',
            Port:           interceptor_port,
            SSLEnable:      true,
            SSLCertName:    [ [ "CN", WEBrick::Utils::getservername ] ],
            SSLEnable:      true,
            SSLCertificate: cert,
            SSLPrivateKey:  pkey,
            ArachniProxy:   method( :proxy_service ),
            ProxyURITest:   @config[:ProxyURITest],
            Logger:         WEBrick::Log::new( '/dev/null', 7 ),
        )

        def @interceptor.service( req, res )
            exclude_reasons = @config[:ProxyURITest].call( req.request_uri )

            if exclude_reasons.empty?
                @config[:ArachniProxy].call( req, res )
            else
                notify( exclude_reasons, req, res )
            end
        end

        Thread.new { @interceptor.start }
        sleep 1
        @interceptor
    end

    def interceptor_port
        @interceptor_port ||= available_port
    end

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

    def service( req, res )
        if req.request_method.downcase == 'connect'
            super( req, res )
            return
        end

        exclude_reasons = @config[:ProxyURITest].call( req.request_uri )

        if exclude_reasons.empty?
            super( req, res )
        else
            notify( exclude_reasons, req, res )
        end
    end

    def perform_proxy_request( req, res )
        response = yield( req.request_uri.to_s, setup_proxy_header( req, res ) )

        # Persistent connection requirements are mysterious for me.
        # So I will close the connection in every response.
        res['proxy-connection'] = "close"
        res['connection'] = "close"

        # Convert Typhoeus::Response to WEBrick::HTTPResponse
        res.status = response.code.to_i
        choose_header( response, res )
        #set_cookie(response, res)
        set_via( res )
        res.body = response.body
    end

    def notify( reasons, req, res )
        res.header['content-type'] = 'text/plain'
        res.header.delete( 'content-encoding' )

        res.body << "#{reasons.pop}\n"
        res.body << reasons.map { |msg| "  *  #{msg}" }.join( "\n" )
    end

end
end
