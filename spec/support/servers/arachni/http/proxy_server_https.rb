require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

options = {
    Port:            ARGV[1].to_i,
    Host:            ARGV[3],
    SSLEnable:       true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLCertName:     [["CN", WEBrick::Utils::getservername]],
}

class HTTPSServer < Sinatra::Base

    get '/' do
        'HTTPS GET'
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( HTTPSServer, options )
