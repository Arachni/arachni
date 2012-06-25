require 'sinatra'
require 'ap'

put '/Arachni-*' do
    body = request.body
    self.class.get( env['REQUEST_PATH'] ) { body }
    status 201
end
