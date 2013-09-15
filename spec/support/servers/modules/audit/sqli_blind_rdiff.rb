require 'sinatra'
require 'sinatra/contrib'

def default
    'default'
end

def get_result( str )
    if str.end_with?( '1=2' )
        'Could not find any results, bugger off!'
    elsif str.end_with?( '1=1' ) || str == default
        '1 item found: Blah blah blah...'
    else
        'No idea what you want mate...'
    end
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
    return if !params['input'].start_with?( default )

    get_result( params['input'] )
end

get "/form" do
    <<-EOHTML
        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/append" do
    return if !params['input'] || !params['input'].start_with?( default )

    get_result( params['input'] )
end


get "/cookie" do
    <<-EOHTML
        <a href="/cookie/append">Cookie</a>
    EOHTML
end

get "/cookie/append" do
    cookies['cookie'] ||= default
    return if !cookies['cookie'].start_with?( default )

    get_result( cookies['cookie'] )
end
