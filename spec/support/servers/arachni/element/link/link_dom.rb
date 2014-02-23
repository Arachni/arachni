require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom#/test/?name=some-name&email=some@email.com'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/dom' do
    <<-EOHTML
    <html>
        <a href='#/test/?name=some-name&email=some@email.com'>DOM link</a>

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
            <div id="container-name">
            </div>
            <div id="container-email">
            </div>

            <script>
                document.getElementById('container-name').innerHTML = getQueryVariable('name');
                document.getElementById('container-email').innerHTML = getQueryVariable('email');
            </script>
        </body>
    </html>
    EOHTML
end
