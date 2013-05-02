require 'yaml'
require 'sinatra'
set :logging, false

def submitted
    { 'param' => env['HTTP_PARAM'] }
end

get '/' do
    submitted.to_s
end

get '/submit' do
    submitted.to_hash.to_yaml
end

get '/sleep' do
    sleep 2
    <<-EOHTML
    #{params[:input]}
    EOHTML
end
