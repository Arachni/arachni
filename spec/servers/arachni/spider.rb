require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    <<EOHTML
    <a href='/this_does_not_exist'> 404 </a>
EOHTML
end

get '/sleep' do
    sleep 2
    <<EOHTML
    <a href='/something'>Stuff</a>
EOHTML
end

get '/something' do
    'Stuff'
end

get '/redirect' do
    redirect '/'
end

get '/skip_redirect' do
    redirect 'http://google.com'
end

get '/stacked_redirect' do
    redirect '/stacked_redirect1'
end

get '/stacked_redirect1' do
    redirect '/stacked_redirect2'
end

get '/stacked_redirect2' do
    redirect '/stacked_redirect3'
end

get '/stacked_redirect3' do
    redirect '/stacked_redirect4'
end

get '/stacked_redirect4' do
end

get '/redundant' do
    <<EOHTML
    <a href='/redundant/1'>Redundant 1</a>
EOHTML
end

get '/redundant/1' do
    <<EOHTML
    <a href='/redundant/2'>Redundant 2</a>
EOHTML
end

get '/redundant/2' do
    <<EOHTML
    <a href='/redundant/3'>Redundant 3</a>
EOHTML
end

get '/redundant/3' do
    'End of the line.'
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

get '/auto-redundant' do
    str = ''
    10.times do
        str += <<-EOHTML
        <a href='/auto-redundant?stuff=#{rand( 999 )}'>Stuff</a>
    EOHTML
    end

    10.times do
        str += <<-EOHTML
        <a href='/auto-redundant?stuff=#{rand( 999 )}&ha=#{rand( 999 )}'>Stuff</a>
        EOHTML
    end

    str
end
