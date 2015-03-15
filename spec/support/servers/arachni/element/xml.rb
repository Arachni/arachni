require 'sinatra'

post '/submit' do
    URI.decode_www_form_component( request.body.read )
end
