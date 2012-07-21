require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    cookies.map { |k, v| k.to_s + v.to_s }.join( "\n" )
end

get '/set_cookie' do
    cookies['my-cookie'] = 'my-val'
    ''
end

get '/with_other_elements' do
    cookies['mycookie'] ||= 'cookie val'
    <<HTML
    <a href='?link_name=link_val'>A link</a>

    <form action='?form_name=form_val'>
        <input name='input' />
        <input name='input2' />
    </form>
HTML
end
