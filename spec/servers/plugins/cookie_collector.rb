require 'sinatra'
require 'sinatra/contrib'

get '/' do
    cookies[:cookie1] = 'val1'

    <<-HTML
        <a href='/a_link'>A link</a>
        <a href='/update_cookie'>Update cookie</a>
    HTML
end

get '/a_link' do
    cookies[:link_followed] = 'yay link!'
end

get '/update_cookie' do
    cookies[:link_followed] = 'updated link!'
    cookies[:stuff] = 'blah'
end
