require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'

@@errors ||= {}
if @@errors.empty?
    Dir.glob( File.dirname( __FILE__ ) + '/no_sql_injection/*' ).each do |path|
        @@errors[File.basename( path )] = IO.read( path )
    end
end

def variations
    @@variations ||= [ '\';.")' ]
end

def get_variations( platform, str )
    @@errors[platform] if variations.include?( str )
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

@@errors.keys.each do |platform|
    platform_str = platform.to_s

    get '/' + platform_str do
        <<-EOHTML
            <a href="/#{platform_str}/link">Link</a>
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
            <a href="/#{platform_str}/link/flip?input=default">Link</a>
            <a href="/#{platform_str}/link/append?input=default">Link</a>
            <a href="/#{platform_str}/link/ignore?input=default">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link/flip" do
        params.keys.map { |k| get_variations( platform, k ) }.to_s
    end

    get "/#{platform_str}/link/append" do
        default = 'default'
        return if !params['input'].start_with?( default )

        get_variations( platform, params['input'].split( default ).last )
    end

    get "/#{platform_str}/link-template" do
        <<-EOHTML
        <a href="/#{platform_str}/link-template/append/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{platform_str}/link-template/append/input/*/stuff" do
        p params
        val = params[:splat].first
        default = 'default'
        return if !val.start_with?( default )

        get_variations( platform, URI.decode( val.split( default ).last.to_s ) )
    end

    get "/#{platform_str}/form" do
        <<-EOHTML
            <form action="/#{platform_str}/form/flip">
                <input name='input' value='default' />
            </form>

            <form action="/#{platform_str}/form/append">
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    get "/#{platform_str}/form/flip" do
        params.keys.map { |k| get_variations( platform, k ) }.to_s
    end

    get "/#{platform_str}/form/append" do
        default = 'default'
        return if !params['input'] || !params['input'].start_with?( default )

        get_variations( platform, params['input'].split( default ).last )
    end

    get "/#{platform_str}/cookie" do
        <<-EOHTML
            <a href="/#{platform_str}/cookie/flip">Cookie</a>
            <a href="/#{platform_str}/cookie/append">Cookie</a>
        EOHTML
    end

    get "/#{platform_str}/cookie/flip" do
        cookies.keys.map { |k| get_variations( platform, k ) }.to_s
    end

    get "/#{platform_str}/cookie/append" do
        default = 'cookie value'
        cookies['cookie2'] ||= default
        return if !cookies['cookie2'].start_with?( default )

        get_variations( platform, cookies['cookie2'].split( default ).last )
    end

    get "/#{platform_str}/header" do
        <<-EOHTML
            <a href="/#{platform_str}/header/flip">Header</a>
            <a href="/#{platform_str}/header/append">Header</a>
        EOHTML
    end

    get "/#{platform_str}/header/flip" do
        env.keys.map do |k|
            get_variations( platform, k.gsub( 'HTTP_', '' ).gsub( '_', '-' ) )
        end.to_s
    end

    get "/#{platform_str}/header/append" do
        default = 'arachni_user'
        return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( platform, env['HTTP_USER_AGENT'].split( default ).last )
    end

    get "/#{platform_str}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/json/flip", true);
                http_request.send( '{"input": "arachni_user"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/json/append", true);
                http_request.send( '{"input": "arachni_user"}' );
            </script>
        EOHTML
    end

    post "/#{platform_str}/json/flip" do
        return if !@json
        @json.keys.map { |k| get_variations( platform, k ) }.to_s
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
                http_request.open( "POST", "/#{platform_str}/xml/text/append", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{platform_str}/xml/attribute/append", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{platform_str}/xml/text/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end

    post "/#{platform_str}/xml/attribute/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if !input.start_with?( default )

        get_variations( platform, input.split( default ).last )
    end
end
