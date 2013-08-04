require 'sinatra'

get '/' do
    <<EOHTML
        <a href="/401">401</a>
        <a href="/403">403</a>
EOHTML
end

get '/401' do
    env['HTTP_X_FORWARDED_FOR'] == '127.0.0.1' ? 200 : 401
end

get '/403' do
    env['HTTP_X_FORWARDED_FOR'] == '127.0.0.1' ? 200 : 403
end
