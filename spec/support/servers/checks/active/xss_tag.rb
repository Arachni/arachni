require 'sinatra'
require 'sinatra/contrib'

get '/' do
    <<-EOHTML
        <a href="/link?input=default">Link</a>
        <a href="/form">Form</a>
        <a href="/cookie">Cookie</a>
        <a href="/header">Header</a>
    EOHTML
end

get "/link" do
    <<-EOHTML
        <a href="/link/no?input=default">Link</a>
        <a href="/link/single?input=default">Link</a>
        <a href="/link/double?input=default">Link</a>
    EOHTML
end

get "/link/no" do
    default = 'default'
    return if !params['input'].start_with?( default )

    "<a href='/' class=#{params['input']}more-stuff>Vuln</a>"
end

get "/link/single" do
    default = 'default'
    return if !params['input'].start_with?( default )

    "<a href='/' class='#{params['input']}more-stuff'>Vuln</a>"
end

get "/link/double" do
    default = 'default'
    return if !params['input'].start_with?( default )

    "<a href='/' class=\"#{params['input']}more-stuff\">Vuln</a>"
end

get "/form" do
    <<-EOHTML
        <form action="/form/no">
            <input name='input' value='default' />
        </form>

        <form action="/form/single">
            <input name='input' value='default' />
        </form>

        <form action="/form/double">
            <input name='input' value='default' />
        </form>
    EOHTML
end

get "/form/no" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    "<a href='/' class=#{params['input']}more-stuff>Vuln</a>"
end

get "/form/single" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    "<a href='/' class='#{params['input']}more-stuff'>Vuln</a>"
end

get "/form/double" do
    default = 'default'
    return if !params['input'] || !params['input'].start_with?( default )

    "<a href='/' class=\"#{params['input']}more-stuff\">Vuln</a>"
end


get "/cookie" do
    <<-EOHTML
        <a href="/cookie/no">Cookie</a>
        <a href="/cookie/single">Cookie</a>
        <a href="/cookie/double">Cookie</a>
    EOHTML
end

get "/cookie/no" do
    default = 'cookie value'
    cookies['cookie'] ||= default
    return if !cookies['cookie'].start_with?( default )

    "<a href='/' class=#{cookies['cookie']}more-stuff>Vuln</a>"
end

get "/cookie/single" do
    default = 'cookie value'
    cookies['cookie1'] ||= default
    return if !cookies['cookie1'].start_with?( default )

    "<a href='/' class='#{cookies['cookie1']}more-stuff'>Vuln</a>"
end

get "/cookie/double" do
    default = 'cookie value'
    cookies['cookie2'] ||= default
    return if !cookies['cookie2'].start_with?( default )

    "<a href='/' class=\"#{cookies['cookie2']}more-stuff\">Vuln</a>"
end

get "/header" do
    <<-EOHTML
        <a href="/header/no">Header</a>
        <a href="/header/single">Header</a>
        <a href="/header/double">Header</a>
    EOHTML
end

get "/header/no" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    "<a href='/' class=#{env['HTTP_USER_AGENT']}more-stuff>Vuln</a>"
end

get "/header/single" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    "<a href='/' class='#{env['HTTP_USER_AGENT']}more-stuff'>Vuln</a>"
end

get "/header/double" do
    default = 'arachni_user'
    return if !env['HTTP_USER_AGENT'] || !env['HTTP_USER_AGENT'].start_with?( default )

    "<a href='/' class=\"#{env['HTTP_USER_AGENT']}more-stuff\">Vuln</a>"
end
