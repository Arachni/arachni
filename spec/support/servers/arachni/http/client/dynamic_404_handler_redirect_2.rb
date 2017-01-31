require 'sinatra'

get '/error/index.html' do
    response.headers['Content-Type'] = 'text/html'
    "custom page"
end

get '*' do
    status 404
    "404 Not Found"
end
