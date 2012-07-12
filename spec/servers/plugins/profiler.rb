require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    cookies['stuff'] = str
    headers 'My-Header' => str

    <<-HTML
    #{str}

    <a href='/?name=#{str}'>Stuff</a>

    <form name='form_name'>
        <input name='blah' value='#{str}' />
    </form>
HTML
end

get '/' do
    <<-HTML
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
    HTML
end

get "/link" do
    <<-HTML
        <a href="/link/append?input=default">Link</a>
    HTML
end

get "/link/append" do
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get "/form" do
    <<-HTML
        <form method='post' name='myform' action="/form/append">
            <input name='input' value='default' />
        </form>
    HTML
end

post "/form/append" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end


get "/cookie" do
    <<-HTML
        <a href="/cookie/append">Cookie</a>
    HTML
end

get "/cookie/append" do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    get_variations( cookies['cookie2'].split( default ).last )
end

get "/header" do
    <<-HTML
        <a href="/header/append">Header</a>
    HTML
end

get "/header/append" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end
