require 'sinatra'
require 'sinatra/contrib'
require_relative '../check_server'

def attributes
    current_check::ATTRIBUTES
end

def get_variations( str )
    attribute = env['PATH_INFO'].split( '/' ).last
    [ '', '"', "'" ].map { |q| "<a href='/' #{attribute}=#{q}#{str.to_s.upcase}#{q}>#{attribute}</a>" }.join
end

get '/' do
    <<-EOHTML
        <a href="/link/?input=default">Link</a>
        <a href="/form/">Form</a>
        <a href="/cookie/">Cookie</a>
        <a href="/header/">Header</a>
    EOHTML
end

get "/link/" do
    attributes.map do |attribute|
        <<-EOHTML
            <a href="#{attribute}?input=default">#{attribute}</a>
        EOHTML
    end.join
end

attributes.each do |attribute|
    get "/link/#{attribute}" do
        get_variations( params['input'] )
    end
end

get "/form/" do
    attributes.map do |attribute|
        <<-EOHTML
            <form action="/form/#{attribute}">
                <input name='input' value='default' />
            </form>
        EOHTML
    end.join
end

attributes.each do |attribute|
    get "/form/#{attribute}" do
        get_variations( params['input'] )
    end
end

get "/cookie/" do
    attributes.map do |attribute|
        cookies[attribute] ||= 'default-' + attribute
        <<-EOHTML
            <a href="#{attribute}">#{attribute}</a>
        EOHTML
    end.join
end

attributes.each do |attribute|
    get "/cookie/#{attribute}" do
        get_variations( cookies[attribute] )
    end
end

get "/header/" do
    attributes.map do |attribute|
        <<-EOHTML
            <a href="#{attribute}">#{attribute}</a>
        EOHTML
    end.join
end

attributes.each do |attribute|
    get "/header/#{attribute}" do
        get_variations( env['HTTP_USER_AGENT'] )
    end
end
