require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'

@@errors ||= {}
if @@errors.empty?
    Dir.glob( File.dirname( __FILE__ ) + '/xpath_injection/*' ).each do |path|
        @@errors[File.basename( path )] = IO.read( path )
    end
end

def variations
    @@variations ||= %w('" ]]]]]]]]] <!--)
end

def get_variations( str )
    @@errors.to_s if variations.include?( str )
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

get '/'do
    <<-EOHTML
        <a href="/link">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
        <a href="/link-template">Link template</a>
        <a href="/json">JSON</a>
        <a href="/xml">XML</a>
    EOHTML
end

get '/link' do
    <<-EOHTML
        <a href="/link/flip?input=default">Link</a>
        <a href="/link/append?input=default">Link</a>
    EOHTML
end

get '/link/flip' do
    params.keys.map { |k| get_variations( k ) }.to_s
end

get '/link/append' do
    default = 'default'
    return if !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/link-template' do
    <<-EOHTML
        <a href="/link-template/append/input/default/stuff">Link</a>
    EOHTML
end

get '/link-template/append/input/*/stuff' do
    val = params[:splat].first
    default = 'default'
    return if !val.start_with?( default )

    get_variations( val.split( default ).last )
end

get '/form' do
    <<-EOHTML
        <form action="/form/flip">
            <input name='input' value='default' />
        </form>

        <form action="/form/append">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get '/form/flip' do
    params.keys.map { |k| get_variations( k ) }.to_s
end

get '/form/append' do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    get_variations( params['input'].split( default ).last )
end

get '/cookie' do
    <<-EOHTML
        <a href="/cookie/flip">Cookie</a>
        <a href="/cookie/append">Cookie</a>
    EOHTML
end

get '/cookie/flip' do
    cookies.keys.map { |k| get_variations( k ) }.to_s
end

get '/cookie/append' do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    get_variations( cookies['cookie2'].split( default ).last )
end

get '/header' do
    <<-EOHTML
        <a href="/header/flip">Header</a>
        <a href="/header/append">Header</a>
    EOHTML
end

get '/header/flip' do
    env.keys.map do |k|
        get_variations( k.gsub( 'HTTP_', '' ).gsub( '_', '-' ) )
    end.to_s
end

get '/header/append' do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    get_variations( env['HTTP_USER_AGENT'].split( default ).last )
end

get "/json" do
    <<-EOHTML
        <script type="application/javascript">
            http_request = new XMLHttpRequest();
            http_request.open( "POST", "/json/straight", true);
            http_request.send( '{"input": "arachni_user"}' );

            http_request = new XMLHttpRequest();
            http_request.open( "POST", "/json/append", true);
            http_request.send( '{"input": "arachni_user"}' );
        </script>
    EOHTML
end

post "/json/straight" do
    return if !@json

    default = 'arachni_user'
    return if @json['input'].start_with?( default )

    get_variations( @json['input'] )
end

post "/json/append" do
    return if !@json

    default = 'arachni_user'
    return if !@json['input'].start_with?( default )

    get_variations( @json['input'].split( default ).last )
end

get "/xml" do
    <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/xml/text/append", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/xml/attribute/straight", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/xml/attribute/append", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
    EOHTML
end

post "/xml/text/straight" do
    return if !@xml

    default = 'arachni_user'
    input = @xml.css('input').first.content

    return if input.start_with?( default )

    get_variations( input )
end

post "/xml/text/append" do
    return if !@xml

    default = 'arachni_user'
    input = @xml.css('input').first.content

    return if !input.start_with?( default )

    get_variations( input.split( default ).last )
end

post "/xml/attribute/straight" do
    return if !@xml

    default = 'arachni_user'
    input = @xml.css('input').first['my-attribute']

    return if input.start_with?( default )

    get_variations( input )
end

post "/xml/attribute/append" do
    return if !@xml

    default = 'arachni_user'
    input = @xml.css('input').first['my-attribute']

    return if !input.start_with?( default )

    get_variations( input.split( default ).last )
end
