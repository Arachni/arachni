require 'sinatra'
set :logging, false

get '/' do
    params.to_s
end
