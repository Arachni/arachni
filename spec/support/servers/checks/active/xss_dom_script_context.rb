require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-EOHTML
        <a href="/link">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
    EOHTML
end

get '/link' do
    <<-EOHTML
        <a href="/link/straight#/?input=default">Link</a>
    EOHTML
end

get '/link/straight' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var query = window.location.hash.split('?')[1];
                var vars = query.split('&');
                for (var i = 0; i < vars.length; i++) {
                    var pair = vars[i].split('=');
                    if (decodeURIComponent(pair[0]) == variable) {
                        return decodeURIComponent(pair[1]);
                    }
                }
            }
        </script>

        <body>
            <script>
                eval(getQueryVariable('input'));
            </script>
        </body>
    </html>
    EOHTML
end

get '/form' do
    <<-EOHTML
        <a href="/form/straight">Form</a>
    EOHTML
end

get '/form/straight' do
    <<-EOHTML
        <script>
            function handleSubmit() {
                eval( document.getElementById('my-input').value );
            }
        </script>

        <form action="javascript:handleSubmit()">
            <input id='my-input' value='default' />
        </form>
    EOHTML
end

get '/cookie' do
    headers 'Set-Cookie' => 'input=value'

    <<-EOHTML
        <a href="/cookie/straight">Form</a>
    EOHTML
end

get '/cookie/straight' do
    <<-EOHTML
        <body>
            <script>
                function getCookie( cname ) {
                    var name = cname + '=';
                    var ca = document.cookie.split(';');

                    for( var i = 0; i < ca.length; i++ ) {
                        var c = ca[i].trim();

                        if( c.indexOf( name ) == 0 ) {
                            return c.substring( name.length, c.length )
                        }
                    }

                    return '';
                }

                eval( getCookie('input') );
            </script>
        </body>
    EOHTML
end
