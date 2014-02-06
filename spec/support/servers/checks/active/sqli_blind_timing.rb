require 'sinatra'
require 'sinatra/contrib'

REGEXP = {
    mysql: 'sleep\(\s?(\d+)\s?\)',
    pgsql: 'pg_sleep\(\s?(\d+)\s?\)',
    mssql: 'waitfor\sdelay\s\'0:0:(\d+)\'',
}

def get_variations( platform, str )
    return if !str

    time = str.scan( Regexp.new( REGEXP[platform] ) ).flatten.first
    return if !time

    sleep( Integer( time ) ) if time
end

REGEXP.keys.each do |platform|

    get "/#{platform}"do
        <<-EOHTML
            <a href="/#{platform}/link?input=default">Link</a>
            <a href="/#{platform}/form">Form</a>
            <a href="/#{platform}/cookie">Cookie</a>
            <a href="/#{platform}/header">Header</a>
        EOHTML
    end

    get "/#{platform}/link" do
        <<-EOHTML
            <a href="/#{platform}/link/straight?input=default">Link</a>
            <a href="/#{platform}/link/append?input=default">Link</a>
        EOHTML
    end

    get "/#{platform}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform}/link/append" do
        default = 'default'
        return if !params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform}/form" do
        <<-EOHTML
            <form action="/#{platform}/form/straight" method='post'>
                <input name='input' value='default' />
            </form>

            <form action="/#{platform}/form/append" method='post'>
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    post "/#{platform}/form/straight" do
        default = 'default'
        return if !params['input'] || params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    post "/#{platform}/form/append" do
        default = 'default'
        return if !params['input'] || !params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform}/cookie" do
        <<-EOHTML
            <a href="/#{platform}/cookie/straight">Cookie</a>
            <a href="/#{platform}/cookie/append">Cookie</a>
        EOHTML
    end

    get "/#{platform}/cookie/straight" do
        default = 'cookie value'
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default )

        get_variations( platform, cookies['cookie'] )
    end

    get "/#{platform}/cookie/append" do
        default = 'cookie value'
        cookies['cookie2'] ||= default
        return if !cookies['cookie2'].start_with?( default )

        get_variations( platform, cookies['cookie2'] )
    end

    get "/#{platform}/header" do
        <<-EOHTML
            <a href="/#{platform}/header/straight">Cookie</a>
            <a href="/#{platform}/header/append">Cookie</a>
        EOHTML
    end

    get "/#{platform}/header/straight" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'] || env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'] )
    end

    get "/#{platform}/header/append" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'] )
    end

end
