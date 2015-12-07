require 'sinatra'
require 'sinatra/contrib'

def default
    'default'
end

def get_result( str )
    str = str.to_s

    if str.end_with?( '1=2' ) || str == '-1839'
        'Could not find any results, bugger off!'
    elsif str.end_with?( '1=1' ) || str == default
        '1 item found: Blah blah blah...'
    else
        'No idea what you want mate...'
    end
end

[:sql].each do |platform|
    get "/#{platform}" do
        <<-EOHTML
            <a href="/#{platform}/link?input=default">Link</a>
            <a href="/#{platform}/form">Form</a>
            <a href="/#{platform}/cookie">Cookie</a>
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
end

