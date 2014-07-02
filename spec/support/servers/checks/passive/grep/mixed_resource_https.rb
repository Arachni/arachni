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
