require 'sinatra'
require 'json'

set :logging, false

get '/' do
    'OK'
end

get '/audit/link' do
    <<EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
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
