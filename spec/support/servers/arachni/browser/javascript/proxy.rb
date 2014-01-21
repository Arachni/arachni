require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<EOHTML
    <html>
        <script>
            _#{params[:token]}ProxyTest = {
                my_property: null,
                my_function: function( number, string, hash ) {
                    return [number, string, hash]
                }
            }
        </script>
    </html>
EOHTML
end
