require 'sinatra'
require 'sinatra/multi_route'

route 'TRACE', '/' do
    "TRACE / HTTP/1.1"
end
