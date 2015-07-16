require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-EOHTML
<html>
    <head>
        <title></title>
    </head>

    <body>
        <div id='container'>
        </div>

        <script>
            document.getElementById('container').innerHTML = decodeURIComponent(document.cookie);
        </script>
    </body>
</html>
    EOHTML
end
