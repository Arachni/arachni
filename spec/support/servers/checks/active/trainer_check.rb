require 'ap'
require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-EOHTML
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
    EOHTML
end

get "/link" do
    <<-EOHTML
        <a href="/link/straight?input=default">Link</a>
        <a href="/link/append?input=default">Link</a>
    EOHTML
end

get "/link/straight" do
    default = 'default'
    return if params['input'].start_with?( default ) ||
        !params['input'].include?( '_arachni_trainer_' )

    redirect "/link/straight/redir"
end

get "/link/straight/redir" do
    <<-EOHTML
        <a href="/link/straight/trained">Stuff</a>
    EOHTML
end

get "/link/append" do
    default = 'default'
    return if !params['input'].start_with?( default ) ||
        !params['input'].include?( '_arachni_trainer_' )

    redirect "/link/append/redir"
end

get "/link/append/redir" do
    <<-EOHTML
        <a href="/link/append/trained">Stuff</a>
    EOHTML
end

get "/form" do
    <<-EOHTML
        <form action="/form/straight">
            <input name='input' value='default' />
        </form>

        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/straight" do
    default = 'default'
    return if !params['input'] || params['input'].start_with?( default )

    redirect "/form/straight/trained"
end

get "/form/straight/trained" do
    <<-EOHTML
        <form action="/form/straight/trained?new_stuff"/>Stuff</form>
    EOHTML
end

get "/form/append" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    redirect "/form/append/trained"
end

get "/form/append/trained" do
    <<-EOHTML
        <form action="/form/append/trained?more_new_stuff"/>Stuff</form>
    EOHTML
end

get "/cookie" do
    <<-EOHTML
        <a href="/cookie/straight">Cookie</a>
        <a href="/cookie/append">Cookie</a>
    EOHTML
end

get "/cookie/straight" do
    default = 'cookie value'
    cookies['cookie'] ||= default

    return if cookies['cookie'].start_with?( default ) ||
        !cookies['cookie'].include?( '_arachni_trainer_' )

    redirect "/cookie/straight/trained"
end

get "/cookie/straight/trained" do
    <<-EOHTML
        <a href="yak"/>Stuff</a>
    EOHTML
end

get "/cookie/append" do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default ) ||
        !cookies['cookie2'].include?( '_arachni_trainer_' )

    redirect "/cookie/append/trained"
end

get "/cookie/append/trained" do
    <<-EOHTML
        <a href="blah"/>Stuff</a>
    EOHTML
end


get "/header" do
    <<-EOHTML
        <a href="/header/straight">Header</a>
        <a href="/header/append">Header</a>
    EOHTML
end

get "/header/straight" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || env['HTTP_USER_AGENT'].start_with?( default ) ||
        !env['HTTP_USER_AGENT'].include?( '_arachni_trainer_' )

    redirect "/header/straight/trained-redir"
end

get '/header/straight/trained-redir' do
    <<-EOHTML
        <a href="/header/straight/trained">Stuff</a>
    EOHTML
end

get "/header/append" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default ) ||
        !env['HTTP_USER_AGENT'].include?( '_arachni_trainer_' )

    redirect "/header/append/trained-redir"
end

get "/header/append/trained-redir" do
    <<-EOHTML
        <a href="/header/append/trained">Stuff</a>
    EOHTML
end
