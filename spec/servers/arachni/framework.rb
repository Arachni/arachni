require 'sinatra'
require 'sinatra/contrib'

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
    <<-HTML
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

get '/congrats' do
    <<-EOHTML
        Congrats, get to the audit!
        <a href='/link'></a>
    EOHTML
end

get '/link' do
    if logged_in?
        <<-EOHTML
            <a href='/link?input=blah'>Inject here</a>
            #{params[:input]}
        EOHTML
    end
end
