require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'
require_relative '../check_server'

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

    # ping runtime is -1 second of the injected payload
    sleep( Integer( time ) - 1) if time
end

def variations
    @@v ||= [ '', '&', '&&', '|', ';' ]
end

def get_variations( platform, str )
    time = str.scan( Regexp.new( REGEXP[platform] ) ).flatten.first
    return if !time

    sleep( Integer( time ) - 1 )

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

REGEXP.keys.each do |platform|
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
        EOHTML
    end

    get "/#{platform_str}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( platform, params['input'] )
    end

    get "/#{platform_str}/link-template" do
        <<-EOHTML
        <a href="/#{platform_str}/link-template/straight/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link-template/straight/input/*/stuff" do
        val = params[:splat].first
        default = 'default'
        return if val.start_with?( default )

        get_variations( platform, val.split( default ).last )
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

    get "/#{platform_str}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/json/straight", true);
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

    get "/#{platform_str}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/attribute/straight", true);
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

    post "/#{platform_str}/xml/attribute/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if input.start_with?( default )

        get_variations( platform, input )
    end

end
