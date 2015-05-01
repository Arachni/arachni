require 'sinatra'

get '/vulnerable' do
    headers 'X-Frame-Options' => ''
end

get '/safe' do
    headers 'X-Frame-Options' => 'DENY'
end
