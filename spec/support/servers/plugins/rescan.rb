require 'sinatra'

get '/' do
    <<HTML
    <a href='/1'></a>
    <a href='/2'></a>
HTML
end

get '/2' do
    <<HTML
    <a href='/3'></a>
    <a href='/4'></a>
HTML
end

get '/3' do
    <<HTML
    <a href='/5'></a>
HTML
end

get '/4' do
    <<HTML
    <a href='/6?input=d'></a>
HTML
end

get '/6' do
    params['input']
end
