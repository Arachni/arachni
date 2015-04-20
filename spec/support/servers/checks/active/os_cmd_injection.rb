require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'
require_relative '../check_server'

STRINGS = {
    unix:    '/bin/cat /etc/passwd',
    bsd:     '/bin/cat /etc/master.passwd',
    aix:     '/bin/cat /etc/security/passwd',
    windows: 'type %SystemDrive%\\\\boot.ini',
}

OUT = {
    unix:    'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
',
    bsd:    'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
',
    aix:    'root:x:0:0:root:/root:/bin/bash
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
    current_check.payloads[system].each do |payload|
        return OUT[system] if payload == str
    end

    ''
end

before do
    request.body.rewind
    begin
        @json = JSON.parse( request.body.read )
    rescue JSON::ParserError
    end
    request.body.rewind

    begin
        @xml = Nokogiri::XML( request.body.read )
    rescue JSON::ParserError
    end
    request.body.rewind
end

STRINGS.keys.each do |platform|
    platform_str = platform.to_s

    get '/' + platform_str do
        <<-EOHTML
            <a href="/#{platform_str}/link?input=default">Link</a>
            <a href="/#{platform_str}/form">Form</a>
            <a href="/#{platform_str}/cookie">Cookie</a>
            <a href="/#{platform_str}/header">Header</a>
            <a href="/#{platform_str}/link-template">Link template</a>
            <a href="/#{platform_str}/json">JSON</a>
            <a href="/#{platform_str}/xml">XML</a>
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

    get "/#{platform_str}/link-template" do
        <<-EOHTML
        <a href="/#{platform_str}/link-template/straight/input/default/stuff">Link</a>
        <a href="/#{platform_str}/link-template/append/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link-template/straight/input/*/stuff" do
        val = URI.decode( params[:splat].first )
        default = 'default'
        return if val.start_with?( default )

        get_variations( platform, val.split( default ).last )
    end

    get "/#{platform_str}/link-template/append/input/*/stuff" do
        val = URI.decode( params[:splat].first )
        default = 'default'
        return if !val.start_with?( default )

        get_variations( platform, val.split( default ).last )
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

    get "/#{platform_str}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/json/straight", true);
                http_request.send( '{"input": "arachni_user"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/json/append", true);
                http_request.send( '{"input": "arachni_user"}' );
            </script>
        EOHTML
    end

    post "/#{platform_str}/json/straight" do
        return if !@json

        default = 'arachni_user'
        return if @json['input'].start_with?( default )

        get_variations( platform, @json['input'] )
    end

    post "/#{platform_str}/json/append" do
        return if !@json

        default = 'arachni_user'
        return if !@json['input'].start_with?( default )

        get_variations( platform, @json['input'].split( default ).last )
    end

    get "/#{platform_str}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/text/append", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/attribute/straight", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/attribute/append", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{platform_str}/xml/text/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if input.start_with?( default )

        get_variations( platform, input )
    end

    post "/#{platform_str}/xml/text/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end

    post "/#{platform_str}/xml/attribute/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if input.start_with?( default )

        get_variations( platform, input )
    end

    post "/#{platform_str}/xml/attribute/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end
end
