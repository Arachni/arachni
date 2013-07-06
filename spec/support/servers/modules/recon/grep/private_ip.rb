require 'sinatra'

get '/' do
    <<-EOHTML
        <a href="/body">Body</a>
        <a href="/header">Header</a>
    EOHTML
end

get '/body' do
    <<-EOHTML
        192.168.1.12
    EOHTML
end

get '/header' do
    headers 'Disclosure' => '192.168.1.121'
end
