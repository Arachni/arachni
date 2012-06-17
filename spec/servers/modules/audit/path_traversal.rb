require 'sinatra'
require 'sinatra/contrib'

FILE_TO_PLATFORM = {
    '/boot.ini'   => :windows,
    '/etc/passwd' => :unix
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

def get_variations( system, str )
    return if !str
    str = str.split( "\0" ).first
    file = File.expand_path( str ).gsub( '//', '/' )

    OUT[FILE_TO_PLATFORM[file]] if system == FILE_TO_PLATFORM[file]
end

OUT.keys.each do |system|
    system_str = system.to_s

    get '/' + system_str do
        <<-EOHTML
            <a href="/#{system_str}/link?input=default">Link</a>
            <a href="/#{system_str}/form">Form</a>
            <a href="/#{system_str}/cookie">Cookie</a>
            <a href="/#{system_str}/header">Header</a>
        EOHTML
    end

    get "/#{system_str}/link" do
        <<-EOHTML
            <a href="/#{system_str}/link/straight?input=default">Link</a>
            <a href="/#{system_str}/link/append?input=default">Link</a>
        EOHTML
    end

    get "/#{system_str}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( system, params['input'] )
    end

    get "/#{system_str}/link/append" do
        default = 'default'
        return if !params['input'].start_with?( default )

        get_variations( system, params['input'].split( default ).last )
    end

    get "/#{system_str}/form" do
        <<-EOHTML
            <form action="/#{system_str}/form/straight" method='post'>
                <input name='input' value='default' />
            </form>

            <form action="/#{system_str}/form/append">
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    post "/#{system_str}/form/straight" do
        default = 'default'
        return if !params['input'] || params['input'].start_with?( default )

        get_variations( system, params['input'] )
    end

    get "/#{system_str}/form/append" do
        default = 'default'
        return if !params['input'] || !params['input'].start_with?( default )

        get_variations( system, params['input'].split( default ).last )
    end


    get "/#{system_str}/cookie" do
        <<-EOHTML
            <a href="/#{system_str}/cookie/straight">Cookie</a>
            <a href="/#{system_str}/cookie/append">Cookie</a>
        EOHTML
    end

    get "/#{system_str}/cookie/straight" do
        default = 'cookie value'
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default )

        get_variations( system, cookies['cookie'] )
    end

    get "/#{system_str}/cookie/append" do
        default = 'cookie value'
        cookies['cookie2'] ||= default
        return if !cookies['cookie2'].start_with?( default )

        get_variations( system, cookies['cookie2'].split( default ).last )
    end

    get "/#{system_str}/header" do
        <<-EOHTML
            <a href="/#{system_str}/header/straight">Cookie</a>
            <a href="/#{system_str}/header/append">Cookie</a>
        EOHTML
    end

    get "/#{system_str}/header/straight" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( system, env['HTTP_USER_AGENT'] )
    end

    get "/#{system_str}/header/append" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( system, env['HTTP_USER_AGENT'].split( default ).last )
    end

end
