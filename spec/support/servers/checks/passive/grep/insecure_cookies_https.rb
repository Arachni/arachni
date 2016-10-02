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

class InsecureCookiesSServer < Sinatra::Base

    get '/' do
        response.set_cookie( "cookie", {
            value:  "value",
            secure: false
        })
        response.set_cookie( "cookie2", {
            value:  "value2",
            secure: false
        })
        response.set_cookie( "cookie3", {
            value:  "value3",
            secure: true
        })
        response.set_cookie( "cookie4", {
            value:  "value4",
            secure: true
        })

        <<EOHTML
<html>
<script>
    document.cookie = "jscookie=blah";
    document.cookie = "jscookie2=blah;secure";
</script>
</html>
EOHTML
    end

end

server = ::Rack::Handler::WEBrick
trap( :INT ) { server.shutdown }

server.run( InsecureCookiesSServer, options )
