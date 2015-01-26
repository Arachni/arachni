require 'sinatra'

get '/' do
    <<EOHTML
        <a href="/1">1</a>
        <a href="/2">2</a>
EOHTML
end

get '/1' do
    headers['Weird'] = 'Value'
end

get '/2' do
    headers['Weird2'] = 'Value2'
end
