require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'

REGEXP = {
    php:    'print\s([0-9]+)\s?\*\s?([0-9]+);',
    perl:   'print\s([0-9]+)\s?\*\s?([0-9]+);',
    python: 'print\s([0-9]+)\s?\*\s?([0-9]+)$',
    asp:    'Response.Write\(\s?([0-9]+)\s?\*\s?([0-9]+)\s?\)'
}

def exec( lang, str, prefix = nil, postfix = nil )
    return if !str

    r = ''
    r << Regexp.escape( prefix ) if prefix
    r << '^' if !(prefix || postfix)
    r << REGEXP[lang]
    r << Regexp.escape( postfix ) if postfix

    x, y = str.scan( Regexp.new( r ) ).flatten
    (x && y) ? Integer( x ) * Integer( y ) : nil
end

def variations
    @@v ||= [ '', ';%s', "\";%s#", "';%s#" ]
end

def get_variations( lang, str )
    variations.map do |v|
        pre, post = v.split( '%s' )
        exec( lang, str, pre, post )
    end.compact.to_s
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

REGEXP.keys.each do |language|
    language_str = language.to_s

    get '/' + language_str do
        <<-EOHTML
            <a href="/#{language_str}/link?input=default">Link</a>
            <a href="/#{language_str}/form">Form</a>
            <a href="/#{language_str}/cookie">Cookie</a>
            <a href="/#{language_str}/header">Header</a>
            <a href="/#{language_str}/link-template">Link template</a>
            <a href="/#{language_str}/json">JSON</a>
            <a href="/#{language_str}/xml">XML</a>
        EOHTML
    end

    get "/#{language_str}/link" do
        <<-EOHTML
            <a href="/#{language_str}/link/straight?input=default">Link</a>
        EOHTML
    end

    get "/#{language_str}/link/straight" do
        default = 'default'
        return if params['input'].start_with?( default )

        get_variations( language, params['input'] )
    end

    get "/#{language_str}/link-template" do
        <<-EOHTML
        <a href="/#{language_str}/link-template/straight/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{language_str}/link-template/straight/input/*/stuff" do
        val = URI.decode( params[:splat].first )
        default = 'default'
        return if val.start_with?( default )

        get_variations( language, val.split( default ).last )
    end

    get "/#{language_str}/form" do
        <<-EOHTML
            <form action="/#{language_str}/form/straight" method='post'>
                <input name='input' value='default' />
            </form>
        EOHTML
    end

    post "/#{language_str}/form/straight" do
        default = 'default'
        return if !params['input'] || params['input'].start_with?( default )

        get_variations( language, params['input'] )
    end

    get "/#{language_str}/cookie" do
        <<-EOHTML
            <a href="/#{language_str}/cookie/straight">Cookie</a>
        EOHTML
    end

    get "/#{language_str}/cookie/straight" do
        default = 'cookie value'
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default )

        get_variations( language, cookies['cookie'] )
    end

    get "/#{language_str}/header" do
        <<-EOHTML
            <a href="/#{language_str}/header/straight">Cookie</a>
        EOHTML
    end

    get "/#{language_str}/header/straight" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( language, env['HTTP_USER_AGENT'] )
    end

    get "/#{language_str}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language_str}/json/straight", true);
                http_request.send( '{"input": "arachni_user"}' );
            </script>
        EOHTML
    end

    post "/#{language_str}/json/straight" do
        return if !@json
        default = 'arachni_user'
        return if @json['input'].start_with?( default )

        get_variations( language, @json['input'] )
    end

    get "/#{language_str}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language_str}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language_str}/xml/attribute/straight", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{language_str}/xml/text/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if input.start_with?( default )

        get_variations( language, input )
    end

    post "/#{language_str}/xml/attribute/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if input.start_with?( default )

        get_variations( language, input )
    end

end
