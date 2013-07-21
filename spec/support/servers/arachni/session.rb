require 'sinatra'
require 'sinatra/contrib'
set :logging, false

enable :sessions

def logged_in?
    cookies[:success] == 'true'
end

get '/' do
    cookies[:success] ||= false

    if logged_in?
        <<-HTML
            <a href='/congrats'>Hi there logged-in user!</a>
        HTML
    else
        redirect '/login'
    end
end

get '/login' do
    cookies[:you_need_to] = 'preserve this'

    <<-HTML
        <form method='post' name='login_form' action="/login">
            <input name='username' value='' />
            <input name='password' type='password' value='' />
            <input name='token' type='hidden' value='secret!' />
        </form>
    HTML
end

get '/multiple' do
    <<-HTML
        <form method='post' name='login_form' action="/blah">
            <input name='password' type='password' value='' />
            <input name='username' value='' />
        </form>

        <form method='post' name='login_form' action="/login">
            <input name='username' value='' />
            <input name='password' type='password' value='' />
            <input name='token' type='hidden' value='secret!' />
        </form>
    HTML
end

post '/login' do
    if params['username'] == 'john' && params['password'] == 'doe' &&
        params['token'] == 'secret!'
        cookies[:success] = true
        redirect '/'
    else
        'Boohoo...'
    end
end

get '/with_nonce' do
    session[:success] ||= false

    cookies['session_cookie'] = 'blah'
    response.set_cookie( "non_session", value: "value_of_cookie", expires: Time.now )

    if session[:success]
        <<-HTML
            <a href='/congrats'>Hi there logged-in user!</a>
        HTML
    else
        redirect '/nonce_login'
    end
end

get '/nonce_login' do
    session[:nonce] = rand( 999 ).to_s

    <<-HTML
        <form method='post' name='login_form' action="/nonce_login">
            <input name='username' value='' />
            <input name='token' type='hidden' value='secret!' />
        </form>

        <form method='post' name='login_form' action="/nonce_login">
            <input name='username' value='' />
            <input name='password' type='password' value='' />
            <input name='token' type='hidden' value='#{session[:nonce]}' />
        </form>
    HTML
end

post '/nonce_login' do
    if params['username'] == 'nonce_john' && params['password'] == 'nonce_doe' &&
        params['token'] == session[:nonce]
        session[:success] = true
        redirect '/with_nonce'
    else
        'Boohoo...'
    end
end

get '/congrats' do
    <<-EOHTML
        Congrats, get to the audit!
        <a href='/link'></a>
    EOHTML
end
