require 'sinatra'

post '/submit' do
    request.body.read
end
