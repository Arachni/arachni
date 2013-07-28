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

get '/with-image' do
    <<HTML
    <img src="/" />
HTML
end

get '/hit-count' do
    @@hit_count.to_s
end

get '/clear-hit-count' do
    @@hit_count = 0
end
