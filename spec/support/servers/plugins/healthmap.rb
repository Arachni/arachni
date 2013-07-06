require 'sinatra'

get '/' do
    <<HTML
    <a href='/vuln?input=stuff'></a>
    <a href='/safe'></a>
HTML
end

get '/safe' do
    'stuff here'
end

get '/vuln' do
    params['input'].to_s
end
