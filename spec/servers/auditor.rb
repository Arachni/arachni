require 'sinatra'
require "sinatra/cookies"
require 'json'
require 'digest/md5'
set :logging, false

get '/' do
    'OK'
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

get '/timeout/false' do
    sleep 2
<<-EOHTML
    <a href='?sleep=0'>Inject here</a>
    #{params[:input]}
EOHTML
end

get '/timeout/true' do
    sleep params[:sleep].to_i
<<-EOHTML
    <a href='?sleep=0'>Inject here</a>
EOHTML
end

get '/timeout/high_response_time' do
    sleep( params[:sleep].to_i + 2 )
    <<-EOHTML
        <a href='?sleep=0'>Inject here</a>
EOHTML
end

get '/sleep' do
    sleep 2
<<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
end

get '/link' do
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
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

get '/log_remote_file_if_exists/true' do
    'Success!'
end

get '/log_remote_file_if_exists/false' do
    [ 404, 'Better luck next time...' ]
end

get '/match_and_log' do
    'Match this!'
end
