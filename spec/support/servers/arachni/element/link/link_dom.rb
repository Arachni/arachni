require 'sinatra'

get '/link' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/test/?param=some-name'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/link/inputtable' do
    <<-EOHTML
    <html>
        <body>
            <a href='/dom/#/test/?input1=value1&input2=value2'>DOM link</a>
        </body>
    </html>
    EOHTML
end

get '/dom/' do
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
            <div id="container">
            </div>

            <script>
                document.getElementById('container').innerHTML = getQueryVariable('param');
            </script>
        </body>
    </html>
    EOHTML
end
