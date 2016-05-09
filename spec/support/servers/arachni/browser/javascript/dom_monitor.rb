require 'sinatra'
require 'sinatra/contrib'

JS_LIB = "#{File.dirname( __FILE__ )}/"

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

get '/elements_with_events/whitelist' do
    <<HTML
    <div id="parent">
        <p id="parent-p">
            <button id="parent-button">Click me</button>
        </p>

        <div id="child">
            <p id="child-p">
                <span id="child-span">Click me too</button>
            </p>
        </div>
    </div>

    <script>
        window.addEventListener( "click", function( window_click ){}, false );
        document.addEventListener( "click", function( document_click ){}, false );
        document.getElementById( "parent" ).addEventListener( "click", function( parent_click ){}, false );
        document.getElementById( "child" ).addEventListener( "click", function( child_click ){}, false );
    </script>
HTML
end

get '/elements_with_events/inherited' do
    <<HTML
    <div id="parent">
        <p id="parent-p">
            <button id="parent-button">Click me</button>
        </p>

        <div id="child">
            <p id="child-p">
                <button id="child-button">Click me too</button>
            </p>
        </div>
    </div>

    <script>
        window.addEventListener( "click", function( window_click ){}, false );
        document.addEventListener( "click", function( document_click ){}, false );
        document.getElementById( "parent" ).addEventListener( "click", function( parent_click ){}, false );
        document.getElementById( "child" ).addEventListener( "click", function( child_click ){}, false );
    </script>
HTML
end

get '/elements_with_events/attributes' do
    <<HTML
    <body>
        <button onclick="handler_1()" id="my-button">Click me</button>
        <button onclick="handler_2()" id="my-button2">Click me too</button>
        <button onclick="handler_3()" id="my-button3">Don't bother clicking me</button>
    </body>
HTML
end

get '/elements_with_events/attributes/inappropriate' do
    <<HTML
    <body>
        <button onselect="handler_1()" id="my-button">Click me</button>
        <button onkeydown="handler_2()" id="my-button2">Click me too</button>
        <button onsubmit="handler_3()" id="my-button3">Don't bother clicking me</button>
    </body>
HTML
end

get '/elements_with_events/listeners' do
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

get '/elements_with_events/listeners/inappropriate' do
    <<HTML
    <button id="my-button">Click me</button>
    <button id="my-button2">Click me too</button>
    <button id="my-button3">Don't bother clicking me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "select", function( my_button_click ){}, false );
        document.getElementById( "my-button" ).addEventListener( "submit", function( my_button_click2 ){}, false );

        document.getElementById( "my-button2" ).addEventListener( "select", function( my_button2_click ){}, false );
    </script>
HTML
end

get '/elements_with_events/listeners/custom' do
    <<HTML
    <button id="my-button">Click me</button>

    <script>
        document.getElementById( "my-button" ).addEventListener( "custom_event", function(){}, false );
    </script>
HTML
end

get '/elements_with_events/jQuery.on' do
    <<HTML
    <script src="/jquery.js"></script>

    <body>
        <button id="my-button">Click me</button>
    </body>

    <script>
        $('#my-button').on( 'click', function (){});
    </script>
HTML
end

get '/elements_with_events/jQuery.on-object-types' do
    <<HTML
    <script src="/jquery.js"></script>

    <body>
        <button id="my-button">Click me</button>
    </body>

    <script>
        $('#my-button').on({
            click: function (){},
            mouseover: function (){}
        });
    </script>
HTML
end

get '/elements_with_events/jQuery.on-selector' do
    <<HTML
    <script src="/jquery.js"></script>

    <body id='body'>
        <script>
            $('body').on( 'click', '#my-button', function (){

            });

            $('body').on( 'mouseover', '#my-button', function (){

            });

            $('body').on( 'click', '#my-button-2', function (){

            });
        </script>

        <button id="my-button">Click me</button>
        <button id="my-button-2">Click me</button>
    </body>
HTML
end

get '/elements_with_events/jQuery.on-object-types-selector' do
    <<HTML
    <script src="/jquery.js"></script>

    <body id='body'>
        <script>
            $('body').on({
                click: function (){},
                mouseover: function (){}
            }, '#my-button');
        </script>

        <button id="my-button">Click me</button>
        <button id="my-button-2">Click me</button>
    </body>
HTML
end

get '/elements_with_events/jQuery.delegate' do
    <<HTML
    <script src="/jquery.js"></script>

    <body id='body'>
        <script>
            $('body').delegate( '#my-button', 'click', function (){});
        </script>

        <button id="my-button">Click me</button>
    </body>
HTML
end

get '/elements_with_events/jQuery.delegate-object-types' do
    <<HTML
    <script src="/jquery.js"></script>

    <body id='body'>
        <script>
            $('body').delegate( '#my-button', {
                click: function (){},
                mouseover: function (){}
            });
        </script>

        <button id="my-button">Click me</button>
    </body>
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

get '/elements_with_events/custom-dot-delimited' do
    <<HTML
    <script src="/jquery.js"></script>

    <button id="my-button">Click me</button>

    <script>
        $('#my-button').on( 'click.stuff', function (){});
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

get '/jquery.js' do
    content_type 'text/javascript'
    IO.read "#{JS_LIB}/jquery-2.0.3.js"
end
