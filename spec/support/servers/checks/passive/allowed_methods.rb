require 'sinatra'

options '/' do
    headers 'Allow' => 'OPTIONS, TRACE, GET, HEAD'
end
