require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-HTML
    <form method='post' name='login_form' action="/login">
        <input name='username' value='' />
        <input name='password' type='password' value='' />
        <input name='token' type='hidden' value='secret!' />
    </form>
    HTML
end

post '/login' do
    if params['username'] == 'sys' && params['password'] == 'admin' &&
        params['token'] == 'secret!'
        <<-HTML
            Hello logged in user!
            <a href='/congrats'>stuff</a>
        HTML
    else
        'Boohoo...'
    end
end

get '/congrats' do
    'Congrats!'
end
