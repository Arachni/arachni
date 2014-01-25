require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<HTML
    <script>
        function updateDOM( arg ) {
            document.getElementById( 'my-div' ).innerHTML =
                '<a href="#' + arg + '">My link</a>';
        }
    </script>

    <button id="my-button">Click me</button>
    <button id="my-button2">Click me too</button>
    <button id="my-button3">Don't bother clicking me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "click", function( ){ updateDOM(1) }, false );
        document.getElementById( "my-button2" ).addEventListener( "click", function( ){ updateDOM(2) }, false );
        document.getElementById( "my-button3" ).addEventListener( "click", function( ){ updateDOM(3) }, false );
    </script>

    <div id="my-div"></div>
HTML
end
