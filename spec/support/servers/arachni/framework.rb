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

get '/fail_4_times' do
    @@tries ||= 0
    @@tries += 1

    if @@tries <= 5
        # Return a 0 error code.
        0
    else
        'Stuff'
    end
end

get '/fail' do
    # Return a 0 error code.
    0
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

get '/crawl' do
    <<-EOHTML
    <a href='/sleep'></a>
    EOHTML
end

get '/sleep' do
    sleep 10
end

get '/redirect' do
    redirect '/redirected'
end

get '/redirected' do
    'Redirected!'
end
