require 'sinatra'
require_relative '../check_server'

get '/' do
    <<-HTML
        <a href="/safe">Safe</a>
        <a href="/empty">Empty</a>
    HTML
end

options '/' do
    headers 'Allow' => 'STUFF, PROPFIND'
end

get '/safe' do

end
options '/safe' do
    headers 'Allow' => ''
end

get '/empty' do
end
options '/empty' do
end
