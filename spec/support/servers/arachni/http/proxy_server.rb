require 'sinatra'

get '/' do
    'GET'
end

get '/sleep' do
    sleep 5
end

get '/text' do
    content_type 'text/html; charset=ss'

    'Blah'.encode( 'ASCII-8BIT' )
end

get '/binary' do
    content_type 'application/binary'

    "\x01\x02\x03".encode( 'ASCII-8BIT' )
end
