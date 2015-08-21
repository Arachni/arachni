require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-EOHTML
        <a href="/link">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/link-template">Link template</a>
        <a href="/input">Input</a>
        <a href="/ui_form">UI Form</a>
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

            function pre_eval( code ) {
                eval( code );
            }
        </script>

        <body>
            <script>
                pre_eval(getQueryVariable('input'));
            </script>
        </body>
    </html>
    EOHTML
end

get '/link-template' do
    <<-EOHTML
        <a href="/link-template/straight#|input|default">Link</a>
    EOHTML
end

get '/link-template/straight' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = decodeURIComponent(window.location.hash).split('|');
                return splits[splits.indexOf( variable ) + 1];
            }

            function pre_eval( code ) {
                eval( code );
            }
        </script>

        <body>
            <div id="container">
            </div>

            <script>
                pre_eval(getQueryVariable('input'));
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
                pre_eval( document.getElementById('my-input').value );
            }

            function pre_eval( code ) {
                eval( code );
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
                            return decodeURIComponent(c.substring( name.length, c.length ))
                        }
                    }

                    return '';
                }

                function pre_eval( code ) {
                    eval( code );
                }

                pre_eval( getCookie('input') );
            </script>
        </body>
    EOHTML
end

get '/input' do
    <<-EOHTML
        <a href="/input/straight">Form</a>
    EOHTML
end

get '/input/straight' do
    <<-EOHTML
        <script>
            function handleOnInput() {
                pre_eval( document.getElementById('my-input').value );
            }

            function pre_eval( code ) {
                eval( code );
            }
        </script>

        <div id="container"></div>

        <input oninput="handleOnInput()" id='my-input' value='default' />
    EOHTML
end

get '/ui_form' do
    <<-EOHTML
        <a href="/ui_form/straight">Form</a>
    EOHTML
end

get '/ui_form/straight' do
    <<-EOHTML
    <html>
        <body>
            <script>
                function handleOnClick() {
                    pre_eval( document.getElementById('my-input').value );
                }

                function pre_eval( code ) {
                    eval( code );
                }
            </script>

            <input id="my-input" type="text">
            <button onclick="handleOnClick()" id="insert">Insert into DOM</button>
        </body>
    </html>
    EOHTML
end
