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
    Port:            ARGV[1].to_i,
    Host:            ARGV.last,
    SSLEnable:       true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLCertificate:  crt,
    SSLPrivateKey:   key,
    SSLCertName:     [["CN", WEBrick::Utils::getservername]],
}

class MixedResourceHTTPSServer < Sinatra::Base

    get '/' do
        <<-EOHTML
            <a href="/vuln_script">Vuln script</a>
            <a href="/ok_script">OK script</a>
            <a href="/relative_script">Relative script</a>

            <a href="/vuln_link">Vuln link</a>
            <a href="/ok_link">OK link</a>
            <a href="/relative_link">Relative link</a>
        EOHTML
    end

    get '/vuln_script' do
        <<-EOHTML
            <script src="http://localhost/stuff.js"></script>
        EOHTML
    end

    get '/ok_script' do
        <<-EOHTML
            <script src="https://localhost/secure_stuff.js"></script>
        EOHTML
    end

    get '/relative_script' do
        <<-EOHTML
            <script src="stuff/secure_stuff.js"></script>
        EOHTML
    end

    get '/vuln_link' do
        <<-EOHTML
            <link rel="stylesheet" type="text/css" href="http://localhost/theme.css" />
        EOHTML
    end

    get '/ok_script' do
        <<-EOHTML
            <link rel="stylesheet" type="text/css" href="https://localhost/secure_theme.css" />
        EOHTML
    end

    get '/relative_link' do
        <<-EOHTML
            <link rel="stylesheet" type="text/css" href="stuff/secure_theme.css" />
        EOHTML
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( MixedResourceHTTPSServer, options )
