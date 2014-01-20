require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<HTML
    <html>
    </html>
HTML
end

get '/timeouts' do
    <<HTML
    <script>
        document.cookie = "timeout=pre"

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1000, 'timeout1', 1000 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1500, 'timeout2', 1500 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 2000, 'timeout3', 2000 )
    </script>
HTML
end

get '/intervals' do
    <<HTML
    <script>
        document.cookie = "timeout=pre"
        setInterval( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 2000, 'timeout1', 2000 )
    </script>
HTML
end

get '/events' do
    <<HTML
    <button id="my-button">Click me</button>
    <button id="my-button2">Click me too</button>
    <button id="my-button3">Don't bother clicking me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "click", function( my_button_click ){}, false );
        document.getElementById( "my-button" ).addEventListener( "click", function( my_button_click2 ){}, false );
        document.getElementById( "my-button" ).addEventListener( "onmouseover", function( my_button_onmouseover ){}, false );

        document.getElementById( "my-button2" ).addEventListener( "click", function( my_button2_click ){}, false );
    </script>
HTML
end
