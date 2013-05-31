require 'sinatra'
require 'sinatra/contrib'

REGEXP = {
    windows: 'ping \-n (\d+) localhost',
    unix:    'sleep (\d+)'
}

def exec( platform, str, prefix = nil, postfix = nil )
    return if !str

    r = ''
    r << Regexp.escape( prefix ) if prefix
    r << '^' if !(prefix || postfix)
    r << ' ' + REGEXP[platform]
    r << Regexp.escape( postfix ) if postfix

    time = str.scan( Regexp.new( r ) ).flatten.first
    return if !time

    sleep( Integer( time ) ) if time
end

def variations
    @@v ||= [ '', '&', '&&', '|', ';' ]
end

def get_variations( platform, str )
    variations.map do |v|
        pre, post = v.split( '%s' )
        exec( platform, str, pre, post )
    end.compact.to_s
end

REGEXP.keys.each do |platform|
    platform_str = platform.to_s

    get '/' + platform_str do
        <<-EOHTML
            <a href="/#{platform_str}/link?input=default">Link</a>
            <a href="/#{platform_str}/form">Form</a>
            <a href="/#{platform_str}/cookie">Cookie</a>
            <a href="/#{platform_str}/header">Header</a>
        EOHTML
    end

    get "/#{platform_str}/link" do
        <<-EOHTML
            <a href="/#{platform_str}/link/straight?input=default">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform_str}/form" do
        <<-EOHTML
            <form action="/#{platform_str}/form/straight" method='post'>
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    post "/#{platform_str}/form/straight" do
        default = 'default'
        return if !params['input'] || params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform_str}/cookie" do
        <<-EOHTML
            <a href="/#{platform_str}/cookie/straight">Cookie</a>
        EOHTML
    end

    get "/#{platform_str}/cookie/straight" do
        default = 'cookie value'
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default )

        get_variations( platform, cookies['cookie'] )
    end

    get "/#{platform_str}/header" do
        <<-EOHTML
            <a href="/#{platform_str}/header/straight">Cookie</a>
        EOHTML
    end

    get "/#{platform_str}/header/straight" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'] || env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'] )
    end

end
