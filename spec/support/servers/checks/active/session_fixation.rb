require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    return if !str

    cookies['session'] = str
end

def logged_in?
    cookies['session'] == 'blah'
end

def ensure_logged_in
    redirect '/' if !logged_in?
end

def greet_user
    'Hello dear user!' if logged_in?
end

get '/' do
    cookies['blah'] ||= 'blah1'
    cookies['blah2'] ||= 'blah2'
    cookies['session'] ||= 'blah'

    <<-EOHTML
        #{greet_user}
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
        <a href="/link-template">Link template</a>
    EOHTML
end

get '/link' do
    ensure_logged_in
    <<-EOHTML
        #{greet_user}
        <a href="/link/straight?input=default">Link</a>
        <a href="/link/append?input=default">Link</a>
    EOHTML
end

get '/link/straight' do
    ensure_logged_in
    default = 'default'
    return if params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
    greet_user
end

get '/link/append' do
    ensure_logged_in
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/link-template' do
    <<-EOHTML
        <a href="/link-template/straight/input/default/stuff">Link</a>
        <a href="/link-template/append/input/default/stuff">Link</a>
    EOHTML
end

get '/link-template/straight/input/*/stuff' do
    val = params[:splat].first
    default = 'default'
    return if val.start_with?( default )

    get_variations( val.split( default ).last )
end

get '/link-template/append/input/*/stuff' do
    val = params[:splat].first
    default = 'default'
    return if !val.start_with?( default )

    get_variations( val.split( default ).last )
end

get '/form' do
    <<-EOHTML
        #{greet_user}
        <form action="/form/straight">
            <input name='input' value='default' />
        </form>

        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get '/form/straight' do
    default = 'default'
    return if !params['input'] || params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/form/append' do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end
