require 'sinatra'

get '/' do
    <<-EOHTML
        <a href="/insecure">Insecure</a>
        <a href="/secure">Secure</a>
    EOHTML
end

get '/insecure' do
    <<-EOHTML
        <form name="insecure">
            <input name="insecure_password" type='password' />
        </form>

        <form id='insecure_2'>
            <input name="insecure_password2" type='password' />
        </form>

    EOHTML
end

get '/secure' do
    <<-EOHTML
        <form>
            <input name='secure' type='password' autocomplete="off"/>
        </form>

        <form autocomplete="off">
            <input name='secure' type='password'/>
        </form>
    EOHTML
end
