require 'sinatra'
require 'sinatra/contrib'

get '/' do
    cookies[:cookie1] = 'val1'

    <<-HTML
        <a href='/link?link_input=blah'>A link</a>
        <form method="post">
            <input name="form-input" />
        </form>
    HTML
end
