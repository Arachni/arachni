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
