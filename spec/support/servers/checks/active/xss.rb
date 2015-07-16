require 'sinatra'
require 'sinatra/contrib'

def get_variations( str )
    str.to_s.upcase
end

def get_dom_case( input )
    <<-EOHTML
        <script>
            function writeToDOM( html ) {
                document.getElementById('sink').innerHTML = html;
            }
        </script>

        <a href="#" onclick='writeToDOM(#{input.inspect});return false;'>Click me</a>
        <div id='sink'></div>
    EOHTML
end

get '/' do
    <<-EOHTML
        <a href="/link?input=default">Link</a>
        <a href="/link-template">Link template</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>

        <a href="/gotchas">Gotchas</a>
    EOHTML
end

get '/gotchas' do
    <<-EOHTML
        <a href="/gotchas/escaped?input=default">Link</a>
        <a href="/gotchas/in_attr?input=default">Link</a>
    EOHTML
end

get '/gotchas/escaped' do
    Rack::Utils.escape( params['input'] )
end

get '/gotchas/in_attr' do
    <<-EOHTML
    <input value="#{params['input']}" />
    EOHTML
end

get '/link' do
    <<-EOHTML
        <a href="/link/in_comment?input=default">Link</a>
        <a href="/link/in_textfield?input=default">Link</a>
        <a href="/link/straight?input=default">Link</a>
        <a href="/link/double_encoded?input=default">Link</a>
        <a href="/link/append?input=default">Link</a>
        <a href="/link/dom?input=default">Link</a>
    EOHTML
end

get '/link/in_textfield' do
    <<-EOHTML
    <textarea>#{params['input']}</textarea>
    EOHTML
end

get '/link/in_comment' do
    <<-EOHTML
        <!-- #{params['input']} -->
    EOHTML
end

get '/link/straight' do
    default = 'default'
    return if params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/link/double_encoded' do
    get_variations( URI.decode( params['input'] ) )
end

get '/link/append' do
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/link/dom' do
    get_dom_case( params[:input] )
end

get '/link-template' do
    <<-EOHTML
        <a href="/link-template/in_comment/input/default/stuff">Link</a>
        <a href="/link-template/straight/input/default/stuff">Link</a>
        <a href="/link-template/double_encoded/input/default/stuff">Link</a>
        <a href="/link-template/append/input/default/stuff">Link</a>
        <a href="/link-template/dom/input/default/stuff">Link</a>
    EOHTML
end

get '/link-template/in_comment/input/*/stuff' do
    val = params[:splat].first

    <<-EOHTML
        <!-- #{val} -->
    EOHTML
end

get '/link-template/straight/input/*/stuff' do
    val = params[:splat].first
    default = 'default'
    return if val.start_with?( default )

    get_variations( val.split( default ).last )
end

get '/link-template/double_encoded/input/*/stuff' do
    val = params[:splat].first
    get_variations( URI.decode( val ) )
end

get '/link-template/append/input/*/stuff' do
    val = params[:splat].first
    default = 'default'
    return if !val.start_with?( default )

    get_variations( val.split( default ).last )
end

get '/link-template/dom/input/*/stuff' do
    val = params[:splat].first
    get_dom_case( val )
end

get '/form' do
    <<-EOHTML
        <form action="/form/in_comment">
            <input name='input' value='default' />
        </form>

        <form action="/form/straight">
            <input name='input' value='default' />
        </form>

        <form action="/form/double_encoded">
            <input name='input' value='default' />
        </form>

        <form action="/form/append">
            <input name='input' value='default' />
        </form>

        <form action="/form/dom">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get '/form/dom' do
    get_dom_case( params[:input] )
end

get '/form/in_comment' do
    <<-EOHTML
        <!-- #{params['input']} -->
    EOHTML
end

get '/form/straight' do
    default = 'default'
    return if !params['input'] || params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/form/double_encoded' do
    get_variations( URI.decode( params['input'].to_s ) )
end

get '/form/append' do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end


get '/cookie' do
    <<-EOHTML
        <a href="/cookie/in_comment">Cookie</a>
        <a href="/cookie/straight">Cookie</a>
        <a href="/cookie/double_encoded">Cookie</a>
        <a href="/cookie/append">Cookie</a>
        <a href="/cookie/dom">Cookie</a>
    EOHTML
end

get '/cookie/dom' do
    default = 'cookie value'
    cookies['cookie'] ||= default

    get_dom_case( cookies['cookie'] )
end

get '/cookie/in_comment' do
    default = 'cookie value'
    cookies['cookie'] ||= default

    <<-EOHTML
        <!-- #{cookies['cookie']} -->
    EOHTML
end

get '/cookie/straight' do
    default = 'cookie value'
    cookies['cookie'] ||= default

    return if cookies['cookie'].start_with?( default )

    get_variations( cookies['cookie'].split( default ).last )
end

get '/cookie/double_encoded' do
    default = 'cookie value'
    cookies['cookie'] ||= default

    get_variations( URI.decode( cookies['cookie'] ) )
end

get '/cookie/append' do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    get_variations( cookies['cookie2'].split( default ).last )
end

get '/header' do
    <<-EOHTML
        <a href="/header/straight">Header</a>
        <a href="/header/append">Header</a>
        <a href="/header/double_encoded">Header</a>
        <a href="/header/dom">Header</a>
    EOHTML
end

get '/header/dom' do
    get_dom_case( env['HTTP_USER_AGENT'] )
end

get '/header/straight' do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end

get '/header/double_encoded' do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT']

    get_variations( URI.decode( env['HTTP_USER_AGENT'] ) )
end

get '/header/append' do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end
