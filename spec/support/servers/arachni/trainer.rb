require 'sinatra'
require 'sinatra/contrib'
set :logging, false

def initial_elements
    cookies[:cookie1] = 'foo'
    <<HTML
    <a href='/?foo=bar'>Link</a>
    <form action="/">
        <input name='input1' />
    </form>
HTML
end

get '/' do
    initial_elements
end

get '/new-paths' do
    s = <<HTML
    <a href='/?foo=bar'>Link</a>
    <form action="/">
        <input name='input1' />
    </form>
HTML
    s + " #{request.env["REQUEST_URI"]}/stuff/here"
end

get '/non_text_content_type' do
    headers 'Content-Type' => "foo"
end

get '/new_form' do
    initial_elements + <<HTML
    <form>
        <input name='input2' />
    </form>
HTML
end

get '/new_link' do
    initial_elements + <<HTML
    <a href='?link_param=bar2'>Link</a>
HTML
end

get '/new_cookie' do
    cookies[:new_cookie] = 'hua!'
    initial_elements
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
