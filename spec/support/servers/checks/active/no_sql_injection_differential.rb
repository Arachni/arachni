require 'sinatra'
require 'sinatra/contrib'
require_relative '../check_server'

def default
    'default'
end

def get_result( str )
    str = str.to_s

    if str.include?( '!this' ) || str.include?( 'return false' ) || str == '-1839'
        'Could not find any results, bugger off!'
    elsif str.include?( 'this' ) || str.include?( 'return true' ) || str == default
        '1 item found: Blah blah blah...'
    else
        'No idea what you want mate...'
    end
end

[:nosql].each do |platform|
    get "/#{platform}" do
        <<-EOHTML
            <a href="/#{platform}/link?input=default">Link</a>
            <a href="/#{platform}/form">Form</a>
            <a href="/#{platform}/cookie">Cookie</a>
            <a href="/#{platform}/nested_cookie">Nested cookie</a>
            <a href="/#{platform}/header">Header</a>
        EOHTML
    end

    get "/#{platform}/link" do
        <<-EOHTML
            <a href="/#{platform}/link/append?input=default">Link</a>
        EOHTML
    end

    get "/#{platform}/link/append" do
        get_result( params['input'] )
    end

    get "/#{platform}/form" do
        <<-EOHTML
            <form action="/#{platform}/form/append">
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    get "/#{platform}/form/append" do
        get_result( params['input'] )
    end


    get "/#{platform}/cookie" do
        <<-EOHTML
            <a href="/#{platform}/cookie/append">Cookie</a>
        EOHTML
    end

    get "/#{platform}/cookie/append" do
        cookies['cookie'] ||= default
        get_result( cookies['cookie'] )
    end

    get "/#{platform}/nested_cookie" do
        <<-EOHTML
            <a href="/#{platform}/nested_cookie/append">Nested cookie</a>
        EOHTML
    end

    get "/#{platform}/nested_cookie/append" do
        default = 'nested cookie value'
        cookies['nested_cookie'] ||= "name=#{default}"

        value = Arachni::NestedCookie.parse_inputs( cookies['nested_cookie'] )['name'].to_s
        return if value.start_with?( default )

        get_result( value )
    end

end
