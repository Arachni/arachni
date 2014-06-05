require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    <<-EOHTML
        <script>#{str.upcase}</script>
    EOHTML
end

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
        <a href="/link/append?input=default">Link</a>
    EOHTML
end

get "/link/append" do
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get "/form" do
    <<-EOHTML
        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/append" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end


get "/cookie" do
    <<-EOHTML
        <a href="/cookie/append">Cookie</a>
    EOHTML
end

get "/cookie/append" do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    get_variations( cookies['cookie2'].split( default ).last )
end

get "/header" do
    <<-EOHTML
        <a href="/header/append">Header</a>
    EOHTML
end

get "/header/append" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end
