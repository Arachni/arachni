require 'sinatra'

get '/vulnerable' do
    headers 'X-Frame-Options' => ''
end

get '/safe' do
    headers 'X-Frame-Options' => 'DENY'
end

get '/non-200' do
    headers 'X-Frame-Options' => ''
    [404, 'Not found']
end
