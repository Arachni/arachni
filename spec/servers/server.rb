require 'sinatra'
require 'json'

set :logging, false

get '/' do
    'OK'
end

get '/auditor/log_remote_file_if_exists/true' do

end

get '/auditor/log_remote_file_if_exists/false' do
    [ 404 ]
end

get '/auditor/match_and_log' do
    'Match this!'
end
