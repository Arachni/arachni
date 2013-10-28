require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    cookies[:cookie1] = 'foo'
   <<HTML
    <a href='?foo=bar'>Link</a>
    <form>
        <input name='input1' />
    </form>
HTML
end

get '/non_text_content_type' do
    headers 'Content-Type' => "foo"
end

get '/new_form' do
    <<HTML
    <form>
        <input name='input2' />
    </form>
HTML
end

get '/new_link' do
    <<HTML
    <a href='?link_param=bar2'>Link</a>
HTML
end

get '/new_cookie' do
    cookies[:new_cookie] = 'hua!'
    ''
end

get '/redirect' do
    ''
end

get '/elems' do
    <<-EOHTML
    <a href='/stuff'></a>
    EOHTML
end

get '/train/redirect' do
    redirect '/train/redirected?msg=blah'
end

get '/train/redirected' do
end

get '/fingerprint' do
    redirect '/fingerprint-this.php?stuff=here'
end

get '/fingerprint-this.php' do
    'Stuff'
end
