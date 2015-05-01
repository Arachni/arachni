require 'sinatra'

get '/vulnerable' do
    headers 'Access-Control-Allow-Origin' => '*'
end

get '/safe' do
end
