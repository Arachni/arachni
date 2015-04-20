require 'ap'
require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'

def default
    "default.html"
end

OUT = {
    php: '<?php
    $q = $_GET["q"];',
    jsp: 'response.setIntHeader( "test" )',
    asp: 'Response.Write "stuff"'
}

def get_variations( language, str )
    return if !str.to_s.end_with? ".#{language}"
    OUT[language]
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

OUT.keys.each do |language|

    get "/#{language}" do
        cookies['cookie'] ||= default

        <<-EOHTML
            <a href="/#{language}/link">Link</a>
            <a href="/#{language}/form">Form</a>
            <a href="/#{language}/cookie">Cookie</a>
            <a href="/#{language}/header">Header</a>
            <a href="/#{language}/link-template">Link template</a>
            <a href="/#{language}/json">JSON</a>
            <a href="/#{language}/xml">XML</a>
        EOHTML
    end

    get "/#{language}/link" do
        <<-EOHTML
            <a href="/#{language}/link/straight.#{language}?input=#{default}">Link</a>
            <a href="/#{language}/link/with_null.#{language}?input=#{default}">Link</a>
        EOHTML
    end

    get "/#{language}/link/straight.#{language}" do
        return if params['input'].include?( "\0" )
        get_variations( language, params['input'] )
    end

    get "/#{language}/link/with_null.#{language}" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( language, params['input'].split( "\0.html" ).first )
    end

    get "/#{language}/link-template" do
        <<-EOHTML
        <a href="/#{language}/link-template/straight/input/default/stuff.#{language}">Link</a>
        <a href="/#{language}/link-template/append/input/default/stuff.#{language}">Link</a>
        EOHTML
    end

    get "/#{language}/link-template/straight/input/*/stuff.#{language}" do
        val = params[:splat].first
        default = 'default'
        return if val.start_with?( default )

        get_variations( language, val.split( default ).last )
    end

    get "/#{language}/link-template/with_null/input/*/stuff.#{language}" do
        val = params[:splat].first
        return if !val.end_with?( "\00.html" )
        get_variations( language, val.split( "\0.html" ).first )
    end

    get "/#{language}/form" do
        <<-EOHTML
            <form action="/#{language}/form/straight.#{language}" method='post'>
                <input name='input' value='#{default}' />
            </form>

            <form action="/#{language}/form/with_null.#{language}" method='post'>
                <input name='input' value='#{default}' />
            </form>

        EOHTML
    end

    post "/#{language}/form/straight.#{language}" do
        return if params['input'].include?( "\0" )
        get_variations( language, params['input'] )
    end

    post "/#{language}/form/with_null.#{language}" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( language, params['input'].split( "\0.html" ).first )
    end

    get "/#{language}/cookie" do
        <<-HTML
            <a href="/#{language}/cookie/straight.#{language}">Cookie</a>
        HTML
    end

    get "/#{language}/cookie/straight.#{language}" do
        get_variations( language, cookies['cookie'] )
    end

    get "/#{language}/header" do
        <<-EOHTML
            <a href="/#{language}/header/straight.#{language}">Header</a>
        EOHTML
    end

    get "/#{language}/header/straight.#{language}" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default ) || env['HTTP_USER_AGENT'].include?( "\0" )

        get_variations( language, env['HTTP_USER_AGENT'] )
    end

    get "/#{language}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/json/straight.#{language}", true);
                http_request.send( '{"input": "#{default}"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/json/with_null.#{language}", true);
                http_request.send( '{"input": "#{default}"}' );
            </script>
        EOHTML
    end

    post "/#{language}/json/straight.#{language}" do
        return if !@json
        return if @json['input'].include?( "\0" )
        get_variations( language, @json['input'] )
    end

    post "/#{language}/json/with_null.#{language}" do
        return if !@json
        return if !@json['input'].end_with?( "\00.html" )

        get_variations( language, @json['input'].split( "\0.html" ).first )
    end

    get "/#{language}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/xml/text/straight.#{language}", true);
                http_request.send( '<input>#{default}</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/xml/text/with_null.#{language}", true);
                http_request.send( '<input>#{default}</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/xml/attribute/straight.#{language}", true);
                http_request.send( '<input my-attribute="#{default}">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{language}/xml/attribute/with_null.#{language}", true);
                http_request.send( '<input my-attribute="#{default}">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{language}/xml/text/straight.#{language}" do
        return if !@xml

        input = @xml.css('input').first.content

        return if input.include?( "\0" )

        get_variations( language, input )
    end

    post "/#{language}/xml/text/with_null.#{language}" do
        return if !@xml

        input = @xml.css('input').first.content

        return if !input.end_with?( "\00.html" )

        get_variations( language, input.split( "\00.html" ).last )
    end

    post "/#{language}/xml/attribute/straight.#{language}" do
        return if !@xml

        input = @xml.css('input').first['my-attribute']

        return if input.include?( "\0" )

        get_variations( language, input )
    end

    post "/#{language}/xml/attribute/with_null.#{language}" do
        return if !@xml

        input = @xml.css('input').first['my-attribute']

        return if !input.end_with?( "\00.html" )

        get_variations( language, input.split( "\00.html" ).last )
    end

end
