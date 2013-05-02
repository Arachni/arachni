require 'sinatra'

require 'ap'

get '/' do
    <<-EOHTML
        <a href="/query/">Query</a>
        <a href="/form_action1/">Form action no quotes</a>
        <a href="/form_action2/">Form action single quotes</a>
        <a href="/form_action3/">Form action double quotes</a>
    EOHTML
end

get '/<*' do
    URI.unescape( env['REQUEST_PATH'] )
end

get '/query/' do
    URI.unescape( env['QUERY_STRING'] )
end

get "/form_action1*" do
    <<-EOHTML
        <form action=#{URI.unescape( env['REQUEST_PATH'] )}>
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form_action2*" do
    <<-EOHTML
        <form action='#{URI.unescape( env['REQUEST_PATH'] )}'>
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form_action3*" do
    <<-EOHTML
        <form action="#{URI.unescape( env['REQUEST_PATH'] )}">
            <input name='input' value='default' />
        </form>
    EOHTML
end
