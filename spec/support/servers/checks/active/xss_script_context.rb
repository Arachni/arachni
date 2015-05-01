require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    <<-EOHTML
        <html>
            <script>#{str}</script>
        </html>
    EOHTML
end

get '/' do
    <<-EOHTML
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
        <a href="/link-template">Link template</a>
    EOHTML
end

get "/link" do
    <<-EOHTML
        <a href="/link/straight?input=default">Link</a>
    EOHTML
end

get "/link/straight" do
    get_variations( params['input'] )
end

get '/link-template' do
    <<-EOHTML
        <a href="/link-template/straight/input/default/stuff">Link</a>
    EOHTML
end

get '/link-template/straight/input/*/stuff' do
    get_variations( params[:splat].first )
end

get "/form" do
    <<-EOHTML
        <form action="/form/straight">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/straight" do
    get_variations( params['input'] )
end


get "/cookie" do
    <<-EOHTML
        <a href="/cookie/straight">Cookie</a>
    EOHTML
end

get "/cookie/straight" do
    cookies['cookie2'] ||= 'default'
    get_variations( cookies['cookie2'] )
end

get "/header" do
    <<-EOHTML
        <a href="/header/straight">Header</a>
    EOHTML
end

get "/header/straight" do
    get_variations( env['HTTP_USER_AGENT'] )
end
