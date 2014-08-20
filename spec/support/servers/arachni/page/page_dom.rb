require 'sinatra'

get '/restore/by-url' do
    <<HTML
    <html>
    <head>
        <script>
            function writeButton(){
                document.getElementById( "inside-container" ).innerHTML =
                    "<a onclick='reachDestination()' href='#destination'>Click me!</a>";
            }

            function reachDestination(){
                document.getElementById( "inside-container" ).innerHTML =
                    "<div id='final-container'><a id='final" + "-vector'>Final vector</a></div>";
            }

            level1_ajax = new XMLHttpRequest();
            level1_ajax.onreadystatechange = function() {
                if( level1_ajax.readyState == 4 && level1_ajax.status == 200 ) {
                    document.getElementById( "container" ).innerHTML = level1_ajax.responseText;

                    if( location.hash == '#destination' ) {
                        writeButton();
                        reachDestination();
                    }
                }
            }

            level1_ajax.open( "GET", "/ajax", true );
            level1_ajax.send();
        </script>
    <head>

    <body>
        <div id="container">
        </div>
    </body>
</html>
HTML
end

get '/restore/by-transitions' do
    <<HTML
    <html>
    <head>
        <script>
            function writeButton(){
                document.getElementById( "inside-container" ).innerHTML =
                    "<a onclick='reachDestination()' href='#destination'>Click me!</a>";
            }

            function reachDestination(){
                document.getElementById( "inside-container" ).innerHTML =
                    "<div id='final-container'><a id='final" + "-vector'>Final vector</a></div>";
            }

            level1_ajax = new XMLHttpRequest();
            level1_ajax.onreadystatechange = function() {
                if( level1_ajax.readyState == 4 && level1_ajax.status == 200 ) {
                    document.getElementById( "container" ).innerHTML = level1_ajax.responseText;
                }
            }

            level1_ajax.open( "GET", "/ajax", true );
            level1_ajax.send();
        </script>
    <head>

    <body>
        <div id="container">
        </div>
    </body>
</html>
HTML
end

get '/ajax' do
    <<HTML
    <a blah="stuff" href="javascript:writeButton();">Click to write button</a>
    <div id="inside-container"></div>
HTML
end
