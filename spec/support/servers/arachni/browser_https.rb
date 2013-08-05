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

class BrowserHTTPSServer < Sinatra::Base

    get '/' do
        <<-HTML
            <html>
                <head>
                    <script>
                        get_ajax = new XMLHttpRequest();
                        get_ajax.onreadystatechange = function() {
                            if( get_ajax.readyState == 4 && get_ajax.status == 200 ) {
                                document.getElementById( "my-div" ).innerHTML = get_ajax.responseText;
                            }
                        }

                        get_ajax.open( "GET", "/get-ajax?ajax-token=my-token", true );
                        get_ajax.send();

                        post_ajax = new XMLHttpRequest();
                        post_ajax.open( "POST", "/post-ajax", true );
                        post_ajax.send( "post-name=post-value" );
                    </script>
                <head>

                <body>
                    <div id="my-div">
                    </div>
                </body>
            </html>
        HTML
    end

    get '/get-ajax' do
        return if params['ajax-token'] != 'my-token'

        <<-HTML
            <form>
                <input name="by-ajax">
            </form>
        HTML
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( BrowserHTTPSServer, options )
