require 'sinatra'
set :logging, false

get '/' do
    env['REQUEST_METHOD'].downcase + params.to_s
end

post '/' do
    env['REQUEST_METHOD'].downcase + env['rack.request.form_hash'].to_s
end
