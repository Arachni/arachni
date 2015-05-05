require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<HTML
    <html>
    </html>
HTML
end

get '/digest' do
    <<HTML
    <html>
        <body onload='void();'>
            <div id="my-id-div" data-arachni-id="18181">
                <div class="my-class-div">
                    <p>Hey <strong>Joe</strong>!</p>
                    <em>blah em</em>
                    <i>blah i</i>
                    <b>blah b</b>
                    <strong>blah strong</strong>
                </div>
                <script>
                    //Do stuff...
                </script>

                <a href='#stuff'>Click me!</a>
            </div>
        </body>
    </html>
HTML
end

get '/digest/p' do
    <<HTML
    <html>
        <body>
            <p>Hey <strong>Joe</strong>!</p>
        </body>
    </html>
HTML
end

get '/digest/data-arachni-id' do
    <<HTML
    <html>
        <body>
            <div id="my-id-div" data-arachni-id="18181">
                <div class="my-class-div">
                </div>
            </div>
        </body>
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
        }, '1500', 'timeout2', 1500 )

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

get '/elements_with_events' do
    <<HTML
    <button onclick="handler_1()" id="my-button">Click me</button>
    <button onclick="handler_2()" id="my-button2">Click me too</button>
    <button onclick="handler_3()" id="my-button3">Don't bother clicking me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "click", function( my_button_click ){}, false );
        document.getElementById( "my-button" ).addEventListener( "click", function( my_button_click2 ){}, false );
        document.getElementById( "my-button" ).addEventListener( "onmouseover", function( my_button_onmouseover ){}, false );

        document.getElementById( "my-button2" ).addEventListener( "click", function( my_button2_click ){}, false );
    </script>
HTML
end

get '/elements_with_events/with-hidden' do
    <<HTML
    <button onclick="handler_1()" id="my-button">Click me</button>
    <button style="display: none" onclick="handler_3()" id="my-button3">Don't bother clicking me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "click", function( my_button_click ){}, false );
    </script>
HTML
end

get '/set_element_ids' do
    <<HTML
        <a name="1" href="by-ajax" id="by-ajax">Stuff 1</a>
        <a name="2" href="">Stuff 2</a>

        <a name="3" href="by-ajax" id="by-ajax-1">Stuff 3</a>
        <a name="4" href="">Stuff 4</a>

    <script>
        document.getElementsByTagName( "a" )[0].addEventListener( "click", function(){}, false )
        document.getElementsByTagName( "a" )[1].addEventListener( "click", function(){}, false )
    </script>
HTML
end
