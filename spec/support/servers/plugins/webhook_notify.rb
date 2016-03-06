require 'sinatra'
require 'json'

post '/hook' do
    [
        request.env['CONTENT_TYPE'],
        request.body.read
    ].to_json
end
