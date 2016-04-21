require 'sinatra'

get '/' do
end

get '/slow' do
    sleep 0.5
end
