require 'sinatra'

get '/' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/param/some-name'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/inputtable' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/input1/value1/input2/value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/dom/' do
    <<-EOHTML
    <html>
        <script>
            function getQueryVariable(variable) {
                var splits = window.location.hash.split('/');
                return decodeURI( splits[splits.indexOf( variable ) + 1] );
            }
        </script>

        <body>
            <div id="container">
            </div>

            <script>
                document.getElementById('container').innerHTML = getQueryVariable('param');
            </script>
        </body>
    </html>
    EOHTML
end
