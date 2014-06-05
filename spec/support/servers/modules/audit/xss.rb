require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    str.upcase
end

get '/' do
    <<-EOHTML
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>

        <a href="/gotchas">Gotchas</a>
    EOHTML
end

get "/gotchas" do
    <<-EOHTML
        <a href="/gotchas/escaped?input=default">Link</a>
        <a href="/gotchas/in_attr?input=default">Link</a>
    EOHTML
end

get "/gotchas/escaped" do
    Rack::Utils.escape( params['input'] )
end

get "/gotchas/in_attr" do
    <<-EOHTML
    <input value="#{params['input']}" />
    EOHTML
end

get "/link" do
    <<-EOHTML
        <a href="/link/in_comment?input=default">Link</a>
        <a href="/link/in_textfield?input=default">Link</a>
        <a href="/link/straight?input=default">Link</a>
        <a href="/link/append?input=default">Link</a>
    EOHTML
end

get "/link/in_textfield" do
    <<-EOHTML
    <textarea>#{params['input']}</textarea>
    EOHTML
end

get "/link/in_comment" do
    <<-EOHTML
        <!-- #{params['input']} -->
    EOHTML
end

get "/link/straight" do
    default = 'default'
    return if params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get "/link/append" do
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get "/form" do
    <<-EOHTML
        <form action="/form/in_comment">
            <input name='input' value='default' />
        </form>

        <form action="/form/straight">
            <input name='input' value='default' />
        </form>

        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/in_comment" do
    <<-EOHTML
        <!-- #{params['input']} -->
    EOHTML
end

get "/form/straight" do
    default = 'default'
    return if !params['input'] || params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get "/form/append" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end


get "/cookie" do
    <<-EOHTML
        <a href="/cookie/in_comment">Cookie</a>
        <a href="/cookie/straight">Cookie</a>
        <a href="/cookie/append">Cookie</a>
    EOHTML
end

get "/cookie/straight" do
    default = 'cookie value'
    cookies['cookie'] ||= default

    return if cookies['cookie'].start_with?( default )

    get_variations( cookies['cookie'].split( default ).last )
end

get "/cookie/append" do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    get_variations( cookies['cookie2'].split( default ).last )
end

get "/header" do
    <<-EOHTML
        <a href="/header/straight">Header</a>
        <a href="/header/append">Header</a>
    EOHTML
end

get "/header/straight" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end

get "/header/append" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end
