require 'sinatra'
require 'sinatra/contrib'
require_relative '../../../../lib/arachni'

@@hit_count       ||= 0
@@image_hit_count ||= 0

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
                document.cookie = 'cookie_name="cookie value"';
                document.write( navigator.userAgent );
            </script>
        </div>
    </body>
</html>
HTML
end

get '/cookies/under/path' do
    <<HTML
<html>
    <body>
        <script type="text/javascript">
            document.cookie = 'cookie_under_path=value';
        </script>
    </body>
</html>
HTML
end

get '/cookies/httpOnly' do
    cookies[:http_only] = 'stuff'
end

get '/cookies/domains' do
    response.set_cookie(
        :include_subdomains,
        value:   'bar1',
        domain: ".#{request.host}"
    )

    response.set_cookie(
        :no_subdomains,
        value:   'bar2',
        domain: request.host
    )

    response.set_cookie(
        :other_domain,
        value:   'bar3',
        domain: 'blah.blah'
    )
end

get '/cookies/expires' do
    cookies[:without_expiration] = 'stuff'

    response.set_cookie(
        :with_expiration,
        value:   'bar',
        expires: Time.parse( '2047-08-01 09:30:12 +0000' )
    )
end

get '/open-new-window' do
    <<HTML
<html>
    <body>
        <script>
            window.open( "/with-ajax" );
        </script>

        <a href="/">Click me!</a>
    </body>
</html>
HTML
end

get '/Content-Security-Policy' do
    headers['Content-Security-Policy'] = "default-src 'self'"

    <<HTML
<html>
    <body>
    </body>
</html>
HTML
end

get '/Date' do
    headers['Date'] = 'Thu, 29 Sep 2016 09:57:11 GMT'

    <<HTML
<html>
<script src="/Date/asset"></script>

    <body>
    </body>
</html>
HTML
end

get '/Date/asset' do
    headers['Date'] = 'Thu, 29 Sep 2016 09:57:11 GMT'
    ''
end

get '/Etag' do
    etag '1'

    <<HTML
<html>
<script src="/Etag/asset"></script>
    <body>
    </body>
</html>
HTML
end

get '/Etag/asset' do
    etag '1'
    ''
end

get '/Last-Modified' do
    headers['Last-Modified'] = 'Wed, 21 Oct 2015 07:28:00 GMT'

    <<HTML
<html>
<script src="/Last-Modified/asset"></script>
    <body>
    </body>
</html>
HTML
end

get '/Last-Modified/asset' do
    headers['Last-Modified'] = 'Wed, 21 Oct 2015 07:28:00 GMT'
    ''
end

get '/Cache-Control' do
    headers['Cache-Control'] = 'public, max-age=300'

    <<HTML
<html>
<script src="/Cache-Control/asset"></script>
    <body>
    </body>
</html>
HTML
end

get '/Cache-Control/asset' do
    headers['Cache-Control'] = 'public, max-age=300'
    ''
end

get '/If-None-Match' do
    etag '1'

    <<HTML
<html>
    <script src="/If-None-Match/asset"></script>

    <body>
    </body>
</html>
HTML
end

get '/If-None-Match/asset' do
    etag '1'
    ''
end

get '/If-Modified-Since' do
    last_modified Time.now - 24*60*60
    expires -1

    <<HTML
<html>
    <script src="/If-Modified-Since/asset"></script>

    <body>
    </body>
</html>
HTML
end

get '/If-Modified-Since/asset' do
    last_modified Time.now - 24*60*60
    expires -1

    ''
end

get '/wait_for_elements' do
    <<HTML
<html>
    <body>
    </body>

    <script>
        setInterval( function(){ document.write( '<button id="matchThis" />' ); }, 5000 );
    </script>
</html>
HTML
end

get '/asset_domains' do
end

get '/asset_domains/link' do
    <<HTML
<html>
    <body>
        <link href="http://blah.link.stuff/link.css" />
    </body>
</html>
HTML
end

get '/asset_domains/input' do
    <<HTML
<html>
    <body>
        <input type="image" src="http://blah.input.stuff/input.png" />
    </body>
</html>
HTML
end

get '/asset_domains/script' do
    <<HTML
<html>
    <body>
        <script src="http://blah.script.stuff/script"></script>
    </body>
</html>
HTML
end

get '/asset_domains/img' do
    <<HTML
<html>
    <body>
        <img src="http://blah.img.stuff/img.png" />
    </body>
</html>
HTML
end

get '/asset_domains/extension/js' do
    <<HTML
<html>
    <body>
        <script src="http://code.jquery.com/jquery-2.1.4.min.js"></script>
    </body>
</html>
HTML
end

get '/ajax_sleep' do
    <<HTML
    <html>
    <head>
        <script>
            level1_ajax = new XMLHttpRequest();
            level1_ajax.onreadystatechange = function() {
                if( level1_ajax.readyState == 4 && level1_ajax.status == 200 ) {
                    document.getElementById( "sleep" ).innerHTML = level1_ajax.responseText;
                }
            }

            level1_ajax.open( "GET", "/sleep?sleep=#{params[:sleep]}", true );
            level1_ajax.send();
        </script>
    <head>

    <body>
        <div id="sleep">
        </div>
    </body>
</html>

HTML
end

get '/sleep' do
    sleep params[:sleep].to_i
    'slept'
end

get '/load_delay' do
        <<HTML
    <script>
        document.cookie = "timeout=pre"

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1000, 'timeout1', 1000 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 2000, 'timeout3', 2000 )

        setTimeout( function( name, value ){
            document.cookie = name + "=post-" + value
        }, 1500, 'timeout2', 1500 )
    </script>
HTML
end

get '/event_digest/default' do
    <<-EOHTML
    <html>
        <body>
        </body>
    </html>
    EOHTML
end

get '/each_element_with_events/set-cookie' do
    <<-EOHTML
    <html>
        <script type="text/javascript">
            function setCookie() {
                document.cookie = 'cookie_name="cookie value"';
            }
        </script>

        <body>
            <button onclick="setCookie()">Set cookie</button>
        </body>
    </html>
    EOHTML
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

get '/each_element_with_events/a/href/empty' do
    <<-EOHTML
    <html>
        <body>
            <a href="">Click me!</a>
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

get '/event_digest/form/default' do
    <<-EOHTML
    <html>
        <body>
            <input type="text" name="stuff" value="blah">
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

get '/fire_event/form/disabled_inputs' do
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
            <input disabled id="email"/>
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

get '/fire_event/form/submit_button' do
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
        <form>
            <textarea name="name" ></textarea>
            <input id="email"/>
            <button onclick="submitForm();return false;" type="submit"/>
        </fom>

        <div id="container-name">
        </div>
        <div id="container-email">
        </div>
    </body>
</html>
    EOHTML
end

get '/fire_event/form/submit_input' do
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
        <form>
            <textarea name="name" ></textarea>
            <input id="email"/>
            <input onclick="submitForm();return false;" type="submit"/>
        </fom>

        <div id="container-name">
        </div>
        <div id="container-email">
        </div>
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

get '/fire_event/form/select' do
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
            <select name="email" id="email"/>
                <option value="the.other.dude@abides.com">The other Dude</option>
                <option value="the.dude@abides.com">The Dude</option>
            </select>
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

get '/test.png' do
    @@image_hit_count += 1
    200
end

[
    :onselect,
    :onchange,
    :onfocus,
    :onblur,
    :onkeydown,
    :onkeypress,
    :onkeyup,
    :oninput
].each do |event|
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

get '/script_sink' do
    <<-EOHTML
    <html>
        <script>
            #{params[:input]};
        </script>
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
        <input type="image" name="myImageButton" src="/test.png">
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

get '/ever-changing-dom' do
    <<HTML
<html>
    <head>
        <title>My title!</title>
    </head>

    <body>
        <a href="#{Time.now.to_i}" onclick="doStuff()">
            Blah
        </a>
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

        <a onmouseover="writeButton();" href="#">Write button</a>
        <a href="javascript:level3();">level3 link</a>
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
            post_ajax.open( "POST", "/post-ajax?post-query=blah", true );
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

get '/with-ajax-xml' do
    <<HTML
<html>
    <head>
        <script>
            post_ajax = new XMLHttpRequest();
            post_ajax.open( "POST", "/post-ajax", true );
            post_ajax.send( '<input>stuff</input>' );
        </script>
    <head>
</html>
HTML
end

get '/with-ajax-json' do
    <<HTML
<html>
    <head>
        <script>
            post_ajax = new XMLHttpRequest();
            post_ajax.open( "POST", "/post-ajax", true );
            post_ajax.send( '#{{ 'post-name' => 'post-value' }.to_json}' );
        </script>
    <head>
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

get '/dom-cookies-names' do
    cookies['http_only_cookie'] = 'stuff1'

    response.set_cookie(
        :js_cookie1,
        value: 'stuff2'
    )
    response.set_cookie(
        :js_cookie2,
        value: 'stuff3'
    )
    response.set_cookie(
        :js_cookie3,
        value: 'blah'
    )

    response.set_cookie(
        :other_path,
        value: 'stuff4',
        path: '/blah/'
    )

    <<HTML
    <html>
        <script>
            function getCookie( cname ) {
                var name = cname + '=';
                var ca = document.cookie.split(';');

                for( var i = 0; i < ca.length; i++ ) {
                    var c = ca[i].trim();

                    if( c.indexOf( name ) == 0 ) {
                        return c.substring( name.length, c.length )
                    }
                }

                return '';
            }

            getCookie('http_only_cookie');
            getCookie('js_cookie1');
            getCookie('js_cookie2');
            getCookie('other_path');
        </script>
    </html>
HTML
end

get '/dom-cookies-values' do
    cookies['http_only_cookie'] = 'stuff1'

    response.set_cookie(
        :js_cookie1,
        value: 'stuff2'
    )
    response.set_cookie(
        :js_cookie2,
        value: 'stuff3'
    )

    response.set_cookie(
        :js_cookie3,
        value: 'blah'
    )

    response.set_cookie(
        :other_path,
        value: 'stuff4',
        path: '/blah/'
    )
    <<HTML
    <html>
        <script>
            function cookiesHaveValue( value ) {
                return document.cookie.indexOf( value ) != -1;
            }

            cookiesHaveValue('stuff1');
            cookiesHaveValue('stuff2');
            cookiesHaveValue('stuff3');
            cookiesHaveValue('stuff4');
        </script>
    </html>
HTML
end

get '/dom-cookies-names-substring' do
    cookies['http_only_cookie'] = 'stuff1'

    response.set_cookie(
        :js_cookie1,
        value: 'stuff2'
    )
    response.set_cookie(
        :js_cookie2,
        value: 'stuff3'
    )
    response.set_cookie(
        :js_cookie3,
        value: 'blah'
    )

    response.set_cookie(
        :other_path,
        value: 'stuff4',
        path: '/blah/'
    )

    <<HTML
    <html>
        <script>
            function getCookie( cname ) {
                var name = cname + '=';
                var ca = document.cookie.split(';');

                for( var i = 0; i < ca.length; i++ ) {
                    var c = ca[i].trim();

                    if( c.indexOf( name ) == 0 ) {
                        return c.substring( name.length, c.length )
                    }
                }

                return '';
            }

            getCookie('http_only_cookie_substring');
            getCookie('js_cookie1_substring');
            getCookie('js_cookie2_substring');
            getCookie('other_path_substring');
        </script>
    </html>
HTML
end

get '/dom-cookies-values-substring' do
    cookies['http_only_cookie'] = 'stuff1'

    response.set_cookie(
        :js_cookie1,
        value: 'stuff2'
    )
    response.set_cookie(
        :js_cookie2,
        value: 'stuff3'
    )

    response.set_cookie(
        :js_cookie3,
        value: 'blah'
    )

    response.set_cookie(
        :other_path,
        value: 'stuff4',
        path: '/blah/'
    )
    <<HTML
    <html>
        <script>
            function cookiesHaveValue( value ) {
                return document.cookie.indexOf( value ) != -1;
            }

            cookiesHaveValue('stuff1_substring');
            cookiesHaveValue('stuff2_substring');
            cookiesHaveValue('stuff3_substring');
            cookiesHaveValue('stuff4_substring');
        </script>
    </html>
HTML
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

get '/5_windows' do
    <<HTML
    <script>
        window.open();
        window.open();
        window.open();
        window.open();
        window.open();
    </script>
HTML
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

get '/trigger_events/with_new_timers/:delay' do |delay|
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

            function addFormAfterDelay() {
                setTimeout( addForm, #{delay} )
            }
        </script>
    <head>

    <body>

        <div id="my-div" onclick="addFormAfterDelay();">
            Test
        </div>
    </body>
</html>
HTML
end

get '/trigger_events/with_new_elements' do
    <<HTML
<html>
    <head>
        <script>
            function addElement() {
                document.getElementById( "my-div" ).innerHTML = "<a href='#blah'>Blah</a>";
                document.getElementsByTagName('a')[0].addEventListener( 'click', function() {} );
            }
        </script>
    <head>

    <body>
        <div id="my-div" onclick="addElement();">
            Test
        </div>
    </body>
</html>
HTML
end

get '/trigger_events/invisible-div' do
    <<HTML
<html>
    <body>
        <div id="invisible-div" style="display: none">
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

get '/image-hit-count' do
    @@image_hit_count.to_s
end

get '/clear-hit-count' do
    @@image_hit_count = @@hit_count = 0
end

get '/to_page/input/with_events' do
    <<-EOHTML
    <html>
        <script>
            function handleOnInput() {
                document.getElementById("container").innerHTML =
                    document.getElementById("my-input").value;
            }
        </script>

        <body>
            <input oninput="handleOnInput();" id="my-input" name="my-input" value="1" />

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/to_page/input/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" name="my-input" value="1" />

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/to_page/textarea/with_events' do
    <<-EOHTML
    <html>
        <script>
            function handleOnInput() {
                document.getElementById("container").innerHTML =
                    document.getElementById("my-input").value;
            }
        </script>

        <body>
            <textarea oninput="handleOnInput();" id="my-input" name="my-input">
            </textarea>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end


get '/to_page/textarea/without_events' do
    <<-EOHTML
    <html>
        <body>
            <textarea id="my-input" name="my-input">
            </textarea>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/to_page/input/button/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <input type="button" id="insert">Insert into DOM</button>

            <div id="container">
            </div>

            <script>
               document.getElementById('insert').addEventListener('click', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end

get '/to_page/input/button/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <input type="button" id="insert">Insert into DOM</button>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end

get '/to_page/button/with_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>

            <script>
               document.getElementById('insert').addEventListener('click', function() {
                    document.getElementById("container").innerHTML =
                        document.getElementById("my-input").value;
               });
            </script>
        </body>
    </html>
    EOHTML
end

get '/to_page/button/without_events' do
    <<-EOHTML
    <html>
        <body>
            <input id="my-input" type="text">
            <button id="insert">Insert into DOM</button>

            <div id="container">
            </div>
        </body>
    </html>
    EOHTML
end
