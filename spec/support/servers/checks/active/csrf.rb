require 'sinatra'
require 'sinatra/contrib'

def logged_in?( cookies )
    cookies[:logged_in] == 'true'
end

def common
    <<-HTML
        <form name='search' action='?'>
            <input name='q' />
        </form>
    HTML
end

get '/' do
    html = common

    if logged_in?( cookies )
        html << <<-HTML
        <form name='insecure_important_form' action='?'>
            <input name='hooa!' value='important stuff' />
        </form>

        <form name='secure_important_form' action='?'>
            <input name='booya!' value='other important stuff' />
            <input type='hidden' name='my_nonce' value='#{rand(999)}' />
        </form>
        HTML
    end

    html
end
