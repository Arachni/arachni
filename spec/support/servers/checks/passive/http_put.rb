require 'sinatra'

put '/Arachni-*' do
    body = request.body.read
    self.class.get( env['REQUEST_PATH'] ) { body }
    status 201
end
