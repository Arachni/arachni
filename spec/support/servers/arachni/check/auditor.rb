require 'sinatra'
require 'sinatra/contrib'
require 'digest/md5'

get '/' do
    'Match this!'
end

get '/s.php' do
    'OK'
end

get '/each_candidate_element' do
    cookies['cookie-input'] = 'blah'

    <<HTML
    <html>
        <body>
            <a href="?link-input=blah">Click me</a>
            <a href="link-template/input/blah">Click me</a>
            <form>
                <input name='form-input'>
            </form>
        </body>
    </html>
HTML
end

get '/each_candidate_dom_element' do
    cookies['cookie-input'] = 'blah'

    <<HTML
    <html>
        <body>
            <a href="?link-input=blah">Click me</a>
            <a href="#/?dom-link-input=blah">Click me</a>
            <form>
                <input name='form-input'>
            </form>

            <a href="#/dom-link-template/input/blah">Click me</a>
        </body>
    </html>
HTML
end

get '/with_javascript' do
    <<HTML
    <html>
        <body>
            <script>
                var f = document.createElement("form");
                f.setAttribute('method',"post");
                f.setAttribute('action',"/taint");

                var i = document.createElement("input");
                i.setAttribute('type',"text");
                i.setAttribute('name',"form_input");

                var s = document.createElement("input");
                s.setAttribute('type',"submit");
                s.setAttribute('value',"Submit");

                f.appendChild(i);
                f.appendChild(s);

                document.getElementsByTagName('body')[0].appendChild(f);


                a = document.createElement('a');
                a.href =  '/taint?link_input=test';
                a.innerHTML = "Link"
                document.getElementsByTagName('body')[0].appendChild(a);

                document.cookie = "cookie_input=cookie-value";
            </script>

            #{cookies[:cookie_input]}
        </body>
    </html>
HTML
end

get '/with_ajax' do
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
            get_ajax.open( "GET", "/taint?link_input=my-val", true );
            get_ajax.send();

            post_ajax = new XMLHttpRequest();
            post_ajax.open( "POST", "/taint", true );
            post_ajax.send( "form_input=post-value" );

            cookie_ajax = new XMLHttpRequest();
            cookie_ajax.open( "GET", "/cookie-taint", true );
            cookie_ajax.send();
        </script>
    <head>

    <body>
        <div id="my-div">
        </div>

        #{cookies[:cookie_taint]}
    </body>
</html>
HTML
end

get '/cookie-taint' do
    cookies[:cookie_taint] ||= 'stuff'
end

get '/taint' do
    params[:link_input]
end

post '/taint' do
    params[:form_input]
end

get '/binary' do
    content_type 'application/stuff'
    "\00\00\00"
end

get '/sleep' do
    sleep 2
end

get '/link' do
    <<-EOHTML
<a href='?input=blah'>Inject here</a>
#{params[:input]}
EOHTML
end

get '/elem_combo' do
    cookies[:cookie_input] ||= 'cookie_blah'
    html =<<-EOHTML
    <form method='get'>
        <input name='form_input' value='form_blah' />
    </form>
    <a href='?link_input=link_blah'>Inject here</a>
EOHTML
    html + params.values.join( "\n" ) + cookies[:cookie_input] + (request.env['HTTP_REFERER'] || '')
end

get '/train/default' do
    default = 'form_blah'
    cookies[:curveball] ||= Digest::MD5.hexdigest( rand( 99999 ).to_s )

    html =<<-EOHTML
    <form method='get' action='?'>
        <input name='step_1' value='#{default}_step_1' />
    </form>
EOHTML

    if params[:step_1] == default + '_step_1'
        html +=<<-EOHTML
        <form method='get' action='?'>
            <input name='step_2' value='#{default}_step_2' />
            <input type="hidden" name="curveball" value="#{cookies[:curveball]}">
        </form>

        EOHTML
    end

    if (params[:step_2] == default + '_step_2') && (params[:curveball] == cookies[:curveball])
        html +=<<-EOHTML
            <a href='?you_made_it=to+the+end+of+the+training'>Inject here</a>
        EOHTML
    end

    if params[:you_made_it]
        html += params[:you_made_it]
    end

    html
end

get '/train/true' do
    default = 'form_blah'
    html =<<-EOHTML
    <form method='get' action='?'>
        <input name='step_1' value='#{default}_step_1' />
    </form>
EOHTML

    if params[:step_1] && params[:step_1] != default + '_step_1'
        html +=<<-EOHTML
        <form method='get' action='?'>
            <input name='you_made_it' value='#{default}_step_2' />
        </form>
        EOHTML
    end

    html + "#{params[:you_made_it]}"
end

get '/session' do
    session_id = 'superdupersessionid'
    cookies['session'] ||= session_id
    cookies['vulnerable'] ||= 'hack me'

    if cookies['session'] == session_id
        cookies['vulnerable']
    end
end

get '/log_remote_file_if_exists/true' do
    'Success!'
end

get '/log_remote_file_if_exists/redirect' do
    redirect '/log_remote_file_if_exists/redirected'
end

get '/log_remote_file_if_exists/redirect/not_found' do
    redirect '/log_remote_file_if_exists/false'
end

get '/log_remote_file_if_exists/redirected' do
    'Sucess!'
end

get '/log_remote_file_if_exists/false' do
    [ 404, 'Better luck next time...' ]
end

get '/log_remote_file_if_exists/custom_404/static/*' do
    'This is a custom 404, try to catch it. ;)'
end

get '/log_remote_file_if_exists/custom_404/invalid/*' do
    'This is a custom 404 which includes the requested resource, try to catch it. ;)' +
    '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end

get '/log_remote_file_if_exists/custom_404/dynamic/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s
end

get '/log_remote_file_if_exists/custom_404/redirect/*' do
    redirect '/log_remote_file_if_exists/redirected'
end

get '/log_remote_file_if_exists/custom_404/combo/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s +
    '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end
