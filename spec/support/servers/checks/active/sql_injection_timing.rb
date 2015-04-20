require 'nokogiri'
require 'json'
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

    get "/#{platform}"do
        <<-EOHTML
            <a href="/#{platform}/link?input=default">Link</a>
            <a href="/#{platform}/form">Form</a>
            <a href="/#{platform}/cookie">Cookie</a>
            <a href="/#{platform}/header">Header</a>
            <a href="/#{platform}/link-template">Link template</a>
            <a href="/#{platform}/json">JSON</a>
            <a href="/#{platform}/xml">XML</a>
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

    get "/#{platform}/link-template" do
        <<-EOHTML
            <a href="/#{platform}/link-template/straight/input/default/stuff">Link</a>
            <a href="/#{platform}/link-template/append/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{platform}/link-template/straight/input/*/stuff" do
        val = params[:splat].first
        default = 'default'
        return if val.start_with?( default )

        get_variations( platform, val.split( default ).last )
    end

    get "/#{platform}/link-template/append/input/*/stuff" do
        val = params[:splat].first
        default = 'default'
        return if !val.start_with?( default )

        get_variations( platform, val.split( default ).last )
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

    get "/#{platform}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/json/straight", true);
                http_request.send( '{"input": "arachni_user"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/json/append", true);
                http_request.send( '{"input": "arachni_user"}' );
            </script>
        EOHTML
    end

    post "/#{platform}/json/straight" do
        return if !@json
        default = 'arachni_user'
        return if @json['input'].start_with?( default )

        get_variations( platform, @json['input'] )
    end

    post "/#{platform}/json/append" do
        return if !@json
        default = 'arachni_user'
        return if !@json['input'].start_with?( default )

        get_variations( platform, @json['input'].split( default ).last )
    end

    get "/#{platform}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/xml/text/append", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/xml/attribute/straight", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform}/xml/attribute/append", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{platform}/xml/text/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if input.start_with?( default )

        get_variations( platform, input )
    end

    post "/#{platform}/xml/text/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end

    post "/#{platform}/xml/attribute/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if input.start_with?( default )

        get_variations( platform, input )
    end

    post "/#{platform}/xml/attribute/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end
end
