require 'sinatra'
set :logging, false

get '/' do
    env['HTTP_MY_HEADER'].to_s
end
