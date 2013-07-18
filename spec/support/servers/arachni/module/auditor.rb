require 'sinatra'
require 'sinatra/contrib'
require 'digest/md5'
set :logging, false

get '/' do
    'Match this!'
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

get '/log_remote_file_if_exists/custom_404/combo/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s +
    '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end


get '/match_and_log' do
    'Match this!'
end
