require 'sinatra'
require 'sinatra/contrib'

@@hit_count ||= 0

get '/' do
    @@hit_count += 1

    cookies[:stuff] = 'true'

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

get '/set-javascript-cookie' do
    <<HTML
    <script>
        document.cookie = "js-cookie-name=js-cookie-value"
    </script>
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

            function inHref() {
                post_ajax = new XMLHttpRequest();
                post_ajax.open( "POST", "/href-ajax", true );
                post_ajax.send( "href-post-name=href-post-value" );
            }
        </script>
    <head>

    <body onmouseover="makePOST();">

        <div id="my-div" onclick="addForm();">
            Test
        </div>

        <a href="javascript:inHref();">Stuff</a>
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
