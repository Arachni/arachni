require 'sinatra'

get '/*' do
    # we add the request path and random number to avoid
    # being seen as a custom 404 handler
    env['REQUEST_PATH'] + 'same crap' + rand( 9 ).to_s
end
