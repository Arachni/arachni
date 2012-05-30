require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    <<EOHTML
    <a href='/this_does_not_exist'> 404 </a>
EOHTML
end

get '/a_pushed_path' do
end

get '/some-path blah! %25&$' do
    <<EOHTML
    <a href='/another weird path %25"&*[$)'> Weird </a>
EOHTML
end

get '/another weird path %25"&*[$)' do
    'test'
end

get '/loop' do
    <<EOHTML
    <a href='/loop_back'> Loop </a>
EOHTML
end

get '/loop_back' do
    <<EOHTML
    <a href='/loop'> Loop </a>
EOHTML
end

get '/with_cookies' do
    cookies['my_cookie'] = 'my value'
    <<EOHTML
    <a href='/with_cookies2'> This needs a cookie </a>
EOHTML
end

get '/with_cookies2' do
    if cookies['my_cookie'] == 'my value'
        <<-EOHTML
        <a href='/with_cookies3'> This needs a cookie </a>
    EOHTML
    end
end

get '/with_cookies3' do
end
