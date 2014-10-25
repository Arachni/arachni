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
            <input type='hidden' name='my_kewl_token' value='da39a3ee5e6b4b0d3255bfef95601890afd80709' />
        </form>
        HTML
    end

    html
end

get '/token_in_name' do
    html = common

    if logged_in?( cookies )
        html << <<-HTML
        <form name='insecure_important_form' action='?'>
            <input name='hooa!' value='important stuff' />
        </form>

        <form name='secure_important_form' action='?'>
            <input name='booya!' value='other important stuff' />
        <input type='hidden' name='da39a3ee5e6b4b0d3255bfef95601890afd80709' />

        <form name='secure_important_form_2' action='?'>
            <input name='blahcsrfblah' value='stuff' />
        </form>

        HTML
    end

    html
end

get '/token_in_action' do
    html = common

    if logged_in?( cookies )
        html << <<-HTML
        <form name='insecure_important_form' action='?'>
            <input name='hooa!' value='important stuff' />
        </form>

        <form name='secure_important_form' action='?da39a3ee5e6b4b0d3255bfef95601890afd80709'>
            <input name='booya!' value='other important stuff' />
        </form>

        <form name='secure_important_form2' action='?da39a3ee5e6b4b0d3255bfef95601890afd80709=test'>
            <input name='booya!' value='other important stuff' />
        </form>

        <form name='secure_important_form3' action='?test=da39a3ee5e6b4b0d3255bfef95601890afd80709'>
            <input name='booya!' value='other important stuff' />
        </form>

        <form name='secure_important_form4' action='?csrf=stuff'>
            <input name='booya!' value='other important stuff' />
        </form>

        <form name='secure_important_form5' action='?stuff=csrf'>
            <input name='booya!' value='other important stuff' />
        </form>
        HTML
    end

    html
end

get '/with_nonce' do
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
