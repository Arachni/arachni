require 'sinatra'
require 'sinatra/contrib'

@@hit_count ||= 0

get '/' do
    @@hit_count += 1

    cookies['This name should be updated; and properly escaped'] =
        'This value should be updated; and properly escaped'

    <<HTML
<html>
    <head>
        <title>My title!</title>
    </head>

    <body>
        <div>
            <script type="text/javascript">
                document.write( navigator.userAgent );
            </script>
        </div>
    </body>
</html>
HTML
end

get '/each_element_with_events/a/href/javascript' do
    <<-EOHTML
    <html>
        <body>
            <a href="javascript:doStuff()">Click me!</a>
        </body>
    </html>
EOHTML
end

get '/each_element_with_events/a/href/regular' do
    <<-EOHTML
    <html>
        <body>
            <a href="/">Click me!</a>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/a/href/out-of-scope' do
    <<-EOHTML
    <html>
        <body>
            <a href="http://google.com">Click me!</a>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/form/input/image' do
    <<-EOHTML
    <html>
        <body>
            <form>
                <input type="text" name="stuff" value="blah">
                <input type="image" name="myImageButton" src="/__sinatra__/404.png">
            </form>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/form/action/javascript' do
    <<-EOHTML
    <html>
        <body>
            <form action="javascript:doStuff()">
                <input type="text" name="stuff" value="blah">
            </form>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/form/action/regular' do
    <<-EOHTML
    <html>
        <body>
            <form action="/">
                <input type="text" name="stuff" value="blah">
            </form>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/form/action/out-of-scope' do
    <<-EOHTML
    <html>
        <body>
            <form action="http://google.com/">
                <input type="text" name="stuff" value="blah">
            </form>
        </body>
    </html>
    EOHTML
end

get '/fire_event/form/onsubmit' do
    <<-EOHTML
<html>
    <script>
        function submitForm() {
            document.getElementById("container-name").innerHTML =
                document.getElementsByName("name")[0].value;

            document.getElementById("container-email").innerHTML =
                document.getElementById("email").value;
        }
    </script>

    <body>
        <form onsubmit="submitForm();return false;">
            <textarea name="name" ></textarea>
            <input id="email"/>
            <input/>
        </fom>

        <div id="container-name">
        </div>
        <div id="container-email">
        </div>
    </body>
</html>
    EOHTML
end

get '/fire_event/form/image-input' do
    <<HTML
    <html>
      <form>
        <input type="text" name="stuff" value="blah">
        <input type="image" name="myImageButton" src="/__sinatra__/404.png">
      </form>
    </html>
HTML
end

[:onkeyup, :onkeypress, :onkeydown, :onchange, :oninput].each do |event|
    get "/fire_event/input/#{event}" do
        <<-EOHTML
<html>
    <script>
        function call_#{event}() {
            document.getElementById("container").innerHTML =
                document.getElementById("name").value;
        }
    </script>

    <body>
        <input #{event}="call_#{event}();" id="name" />

        <div id="container">
        </div>
    </body>
</html>
        EOHTML
    end

end

get '/lots_of_sinks' do
    <<-EOHTML
    <html>
        <script>
            function onClick( some, arguments, here ) {
                #{params[:input]};
                onClick3();
                return false;
            }

            function onClick2( some, arguments, here ) {
                onClick( 1, 2 );
            }

            function onClick3( some, arguments, here ) {
                #{params[:input]};
            }
        </script>

        <a href="#" onmouseover="onClick2('blah1', 'blah2', 'blah3');">Blah</a>

        <form id="my_form" onsubmit="onClick('some-arg', 'arguments-arg', 'here-arg'); return false;">
        </form>
    </html>
    EOHTML
end

get '/skip-invisible-elements' do
    <<HTML
    <html>
      <body>
        <script type="text/javascript">
            function doStuff() {
                document.write( navigator.userAgent );
            }
        </script>

        <button id="my-button" onclick="doStuff();">Stuff</button>
      </body>
    </html>
HTML
end

get '/form-with-image-button' do
    <<HTML
    <html>
      <form>
        <input type="text" name="stuff" value="blah">
        <input type="image" name="myImageButton" src="/__sinatra__/404.png">
      </form>
    </html>
HTML
end

get '/event-tracker' do
    <<HTML
    <script>
        window.addEventListener( "load", handlerLoad, false );

        function handlerLoad() {
            document.getElementById( "button" ).addEventListener( "click", handlerClick, false )
        }

        function handlerClick() {
            document.getElementById( "console" ).innerHMTL += 'Clicked!'
        }
    </script>

    <button onmouseover="doStuff();" id="button">click me</button>

    <div id='console'></div>
HTML
end

get '/ever-changing' do
    <<HTML
<html>
    <head>
        <title>My title!</title>
    </head>

    <body>
        <div>
            #{Time.now.to_i}
        </div>
    </body>
</html>
HTML
end

get '/ever-changing-via-js' do
    <<HTML
<html>
    <head>
        <title>My title!</title>
    </head>

    <body>
        <div>
            <script type="text/javascript">
                document.write( new Date() );
            </script>
        </div>
    </body>
</html>
HTML
end

get '/set-javascript-cookie' do
    <<HTML
    <script>
        document.cookie = "js-cookie-name=js-cookie-value"
    </script>
HTML
end

get '/play-transitions' do
    <<HTML
    <html>
    <head>
        <script>
            function writeUserAgent(){
                document.getElementById( "transition1" ).innerHTML = navigator.userAgent;
            }

            function writeButton(){
                document.getElementById( "transition1" ).innerHTML =
                    "<button onclick='writeUserAgent();'>Write user agent</button>";
            }

            level1_ajax = new XMLHttpRequest();
            level1_ajax.onreadystatechange = function() {
                if( level1_ajax.readyState == 4 && level1_ajax.status == 200 ) {
                    document.getElementById( "transition1" ).innerHTML = level1_ajax.responseText;
                }
            }

            level1_ajax.open( "GET", "/transition1", true );
            level1_ajax.send();
        </script>
    <head>

    <body>
        <div id="transition1">
        </div>
    </body>
</html>

HTML
end

get '/transition1' do
    <<HTML
    <a blah="stuff" href="javascript:writeButton();">Click to write button</a>
HTML
end

get '/deep-dom' do
    <<HTML
<html>
    <head>
        <script>
            function writeUserAgent(){
                document.getElementById( "level2" ).innerHTML = navigator.userAgent;
            }

            function writeButton(){
                document.getElementById( "level2" ).innerHTML =
                    "<button onclick='writeUserAgent();'>Write user agent</button>";
            }

            function level3() {
                ajax = new XMLHttpRequest();
                ajax.onreadystatechange = function() {
                    if( ajax.readyState == 4 && ajax.status == 200 ) {
                        document.getElementById( "level3" ).innerHTML = ajax.responseText;
                    }
                }

                ajax.open( "GET", "/level4", true );
                ajax.send();
            }

            function level6() {
                ajax = new XMLHttpRequest();
                ajax.onreadystatechange = function() {
                    if( ajax.readyState == 4 && ajax.status == 200 ) {
                        document.getElementById( "level6" ).innerHTML = ajax.responseText;
                    }
                }

                ajax.open( "GET", "/level6", true );
                ajax.send();
            }


            level1_ajax = new XMLHttpRequest();
            level1_ajax.onreadystatechange = function() {
                if( level1_ajax.readyState == 4 && level1_ajax.status == 200 ) {
                    document.getElementById( "level1" ).innerHTML = level1_ajax.responseText;
                }
            }

            level1_ajax.open( "GET", "/level2", true );
            level1_ajax.send();
        </script>
    <head>

    <body>
        <div id="level1">
        </div>
    </body>
</html>
HTML
end

get '/level2' do
    <<HTML
    <div id="level2">
        <div id="level3">
        </div>

        <a onmouseover="writeButton();" href="javascript:level3();">level3 link</a>
    </div>
HTML
end

get '/level4' do
    <<HTML
    <div id="level4">
        <div id="level6">
        </div>

        <div onclick="level6();" id="level5">
            Level 5 div
        </div>
    </div>
HTML
end

get '/level6' do
    <<HTML
    <form>
        <input name="by-ajax">
    </form>
HTML
end

get '/with-ajax' do
    <<HTML
<html>
    <head>
        <script>
            get_ajax = new XMLHttpRequest();
            get_ajax.onreadystatechange = function() {
                if( get_ajax.readyState == 4 && get_ajax.status == 200 ) {
                    document.getElementById( "my-div" ).innerHTML = get_ajax.responseText;
                }
            }

            get_ajax.open( "GET", "/get-ajax?ajax-token=my-token", true );
            get_ajax.send();

            post_ajax = new XMLHttpRequest();
            post_ajax.open( "POST", "/post-ajax", true );
            post_ajax.send( "post-name=post-value" );
        </script>
    <head>

    <body>
        <div id="my-div">
        </div>
    </body>
</html>
HTML
end

get '/get-ajax' do
    return if params['ajax-token'] != 'my-token'

    <<HTML
    <form>
        <input name="by-ajax">
    </form>
HTML
end

get '/cookie-test' do
    <<HTML
    <div id="cookies">#{cookies.to_hash}</div>
HTML
end

get '/update-cookies' do
    cookies[:update] = 'this'
end

get '/with-image' do
    @@image_hit = false
    <<HTML
    <img src="/image.png" />
HTML
end

get '/image.png' do
    @@image_hit = true
end

get '/image-hit' do
    @@image_hit.to_s
end

get '/explore' do
    <<HTML
<html>
    <head>
        <script>
            function addForm() {
                get_ajax = new XMLHttpRequest();
                get_ajax.onreadystatechange = function() {
                    if( get_ajax.readyState == 4 && get_ajax.status == 200 ) {
                        document.getElementById( "my-div" ).innerHTML = get_ajax.responseText;
                    }
                }

                get_ajax.open( "GET", "/get-ajax?ajax-token=my-token", true );
                get_ajax.send();
            }

            function makePOST() {
                post_ajax = new XMLHttpRequest();
                post_ajax.open( "POST", "/post-ajax", true );
                post_ajax.send( "post-name=post-value" );
            }

            function inHref() {
                post_ajax = new XMLHttpRequest();
                post_ajax.onreadystatechange = function() {
                    if( post_ajax.readyState == 4 && post_ajax.status == 200 ) {
                        document.getElementById( "my-div2" ).innerHTML = post_ajax.responseText;
                    }
                }

                post_ajax.open( "POST", "/href-ajax", true );
                post_ajax.send( "href-post-name=href-post-value" );
            }
        </script>
    <head>

    <body onmouseover="makePOST();">

        <div id="my-div" onclick="addForm();">
            Test
        </div>

        <div id="my-div2">
            Test2
        </div>

        <a href="javascript:inHref();">Stuff</a>
    </body>
</html>
HTML
end

get '/explore-new-window' do
    <<HTML
<html>
    <head>
        <script>
            function oldWindowEvent() {
                post_ajax = new XMLHttpRequest();
                post_ajax.open( "POST", "/post-ajax", true );
                post_ajax.send( "in-old-window=post-value" );
            }
        </script>
    <head>

    <body>

        <div id="my-div" onclick="oldWindowEvent();">
        </div>

        <a href="javascript:window.open( '/new-window', 'new-window', 'resizable=yes,width=500,height=400');">
            Open new window
        </a>
    </body>
</html>
HTML
end

get '/new-window' do
    <<HTML
    <form>
        <input name="in-new-window" />
    </form>
HTML
end

get '/visit_links' do
    <<HTML
<html>
    <head>
        <script>
            function inHref() {
                post_ajax = new XMLHttpRequest();

                post_ajax.onreadystatechange = function() {
                    if( post_ajax.readyState == 4 && post_ajax.status == 200 ) {
                        document.getElementById( "my-div" ).innerHTML = post_ajax.responseText;
                    }
                }


                post_ajax.open( "POST", "/href-ajax", true );
                post_ajax.send( "href-post-name=href-post-value" );
            }
        </script>
    <head>

    <body>
        <div id="my-div">
            Test
        </div>

        <a href="javascript:inHref();">Stuff</a>
    </body>
</html>
HTML
end

post '/href-ajax' do

    <<HTML
    <form>
        <input name="from-post-ajax">
    </form>
HTML
end

get '/visit_links-sleep' do
    <<HTML
<html>
    <head>
        <script>
            function inHref() {
                post_ajax = new XMLHttpRequest();
                post_ajax.open( "POST", "/href-ajax-sleep", true );
                post_ajax.send( "href-post-name-sleep=href-post-value" );
            }
        </script>
    <head>

    <body>
        <a href="javascript:inHref();">Stuff</a>
    </body>
</html>
HTML
end

post '/href-ajax-sleep' do
    sleep 4
end

get '/trigger_events' do
    <<HTML
<html>
    <head>
        <script>
            function addForm() {
                get_ajax = new XMLHttpRequest();
                get_ajax.onreadystatechange = function() {
                    if( get_ajax.readyState == 4 && get_ajax.status == 200 ) {
                        document.getElementById( "my-div" ).innerHTML = get_ajax.responseText;
                    }
                }

                get_ajax.open( "GET", "/get-ajax?ajax-token=my-token", true );
                get_ajax.send();
            }

            function makePOST() {
                post_ajax = new XMLHttpRequest();
                post_ajax.open( "POST", "/post-ajax", true );
                post_ajax.send( "post-name=post-value" );
            }
        </script>
    <head>

    <body onmouseover="makePOST();">

        <div id="my-div" onclick="addForm();">
            Test
        </div>
    </body>
</html>
HTML
end


get '/trigger_events-wait-for-ajax' do
    <<HTML
<html>
    <head>
        <script>
            function addForm() {
                get_ajax = new XMLHttpRequest();
                get_ajax.onreadystatechange = function() {
                    if( get_ajax.readyState == 4 && get_ajax.status == 200 ) {
                        document.getElementById( "my-div" ).innerHTML = get_ajax.responseText;
                    }
                }

                get_ajax.open( "GET", "/get-ajax-with-sleep?ajax-token=my-token", true );
                get_ajax.send();
            }
        </script>
    <head>

    <body>
        <div id="my-div" onclick="addForm();">
            Test
        </div>
    </body>
</html>
HTML
end

get '/get-ajax-with-sleep' do
    return if params['ajax-token'] != 'my-token'

    sleep 4
    <<HTML
    <form>
        <input name="by-ajax">
    </form>
HTML
end

get '/hit-count' do
    @@hit_count.to_s
end

get '/clear-hit-count' do
    @@hit_count = 0
end
