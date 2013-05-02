require 'sinatra'
require 'sinatra/contrib'

STRINGS = {
    unix:    '/bin/cat /etc/passwd',
    windows: 'type %SystemDrive%\\\\boot.ini',
}

OUT = {
    unix:    'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
',
    windows: '[boot loader]
timeout=30
default=multi(0)disk(0)rdisk(0)partition(1)\WINDOWS
[operating systems]
multi(0)disk(0)rdisk(0)partition(1)\WINDOWS="Microsoft Windows XP Professional" /fastdetect
',
}

def exec( system, str, prefix = nil, postfix = nil )
    OUT[system] if "#{prefix} #{STRINGS[system]}#{postfix}" == str
end

def variations
    @@v ||= [ '', '&&', '|', ';' ]
end

def get_variations( system, str )
    (variations.map do |v|
        pre, post = v.split( '%s' )
        exec( system, str, pre, post )
    end | [ exec( system, str, "`", "`" ) ] ).compact.to_s
end

STRINGS.keys.each do |platform|
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
            <a href="/#{platform_str}/link/append?input=default">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform_str}/link/append" do
        default = 'default'
        return if !params['input'].start_with?( default )

        get_variations( platform, params['input'].split( default ).last )
    end

    get "/#{platform_str}/form" do
        <<-EOHTML
            <form action="/#{platform_str}/form/straight" method='post'>
                <input name='input' value='default' />
            </form>

            <form action="/#{platform_str}/form/append">
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    post "/#{platform_str}/form/straight" do
        default = 'default'
        return if !params['input'] || params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform_str}/form/append" do
        default = 'default'
        return if !params['input'] || !params['input'].start_with?( default )

        get_variations( platform, params['input'].split( default ).last )
    end


    get "/#{platform_str}/cookie" do
        <<-EOHTML
            <a href="/#{platform_str}/cookie/straight">Cookie</a>
            <a href="/#{platform_str}/cookie/append">Cookie</a>
        EOHTML
    end

    get "/#{platform_str}/cookie/straight" do
        default = 'cookie value'
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default )

        get_variations( platform, cookies['cookie'] )
    end

    get "/#{platform_str}/cookie/append" do
        default = 'cookie value'
        cookies['cookie2'] ||= default
        return if !cookies['cookie2'].start_with?( default )

        get_variations( platform, cookies['cookie2'].split( default ).last )
    end

    get "/#{platform_str}/header" do
        <<-EOHTML
            <a href="/#{platform_str}/header/straight">Cookie</a>
            <a href="/#{platform_str}/header/append">Cookie</a>
        EOHTML
    end

    get "/#{platform_str}/header/straight" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'] )
    end

    get "/#{platform_str}/header/append" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'].split( default ).last )
    end

end
