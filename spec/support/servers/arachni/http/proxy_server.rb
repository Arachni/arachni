require 'sinatra'

get '/' do
    'GET'
end

get '/sleep' do
    sleep 5
end
