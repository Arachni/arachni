require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

options = {
    Port:            ARGV[1].to_i,
    Host:            ARGV.last,
    SSLEnable:       true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLCertName:     [["CN", WEBrick::Utils::getservername]],
}

class BrowserHTTPSServer < Sinatra::Base

    get '/' do
        headers 'Strict-Transport-Security' => 'max-age=9999'

        <<-HTML
            <a href='/vulnerable'>Vulnerable</a>
            <a href='/safe'>Safe</a>
        HTML
    end

    get '/vulnerable' do
    end

    get '/safe' do
        headers 'Strict-Transport-Security' => 'max-age=9999'
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( BrowserHTTPSServer, options )
