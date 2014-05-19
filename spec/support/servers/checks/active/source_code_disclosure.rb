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

OUT.keys.each do |language|

    get "/#{language}" do
        cookies['cookie'] ||= default

        <<-EOHTML
        <a href="/#{language}/link">Link</a>
        <a href="/#{language}/form">Form</a>
        <a href="/#{language}/cookie">Cookie</a>
        <a href="/#{language}/header">Header</a>
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

end
