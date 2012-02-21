require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    cookies.map { |k, v| k.to_s + v.to_s }.join( "\n" )
end
