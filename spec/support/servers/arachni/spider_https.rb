require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

name = "/C=US/ST=SomeState/L=SomeCity/O=Organization/OU=Unit/CN=localhost"
ca  = OpenSSL::X509::Name.parse( name )
key = OpenSSL::PKey::RSA.new( 1024 )
crt = OpenSSL::X509::Certificate.new

crt.version = 2
crt.serial  = 1
crt.subject = ca
crt.issuer  = ca
crt.public_key = key.public_key
crt.not_before = Time.now
crt.not_after  = Time.now + 1 * 365 * 24 * 60 * 60 # 1 year

options = {
    Port:            ARGV.first.gsub( /\D/, '' ).to_i,
    SSLEnable:       true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLCertificate:  crt,
    SSLPrivateKey:   key,
    SSLCertName:     [["CN", WEBrick::Utils::getservername]],
}

class SpiderHTTPSServer < Sinatra::Base

    get '/' do
        <<-EOHTML
            <a href="/redirect">redirect</a>
            <a href="/redirect_to_http">redirect</a>
        EOHTML
    end

    get '/redirect' do
        redirect '/stuff'
    end

    get '/stuff' do
        'Stuff'
    end

    get '/got_to_https' do
        'Stuff'
    end

    get '/redirect_to_http' do
        redirect 'http://test.com/'
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( SpiderHTTPSServer, options )
