require 'sinatra'

get '/' do
end

get '/slow' do
    sleep 1
end
