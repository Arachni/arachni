require 'sinatra'

get '/' do
    <<-EOHTML
        <a href="/insecure">Insecure</a>
        <a href="/secure">Secure</a>
    EOHTML
end

get '/insecure' do
    <<-EOHTML
        <form>
            <input name='insecure' type='password' />
        </form>

        <form>
            <input name='insecure_2' type='password' />
        </form>

        Will be ignored.
        <form>
            <input type='password' />
        </form>
    EOHTML
end

get '/secure' do
    <<-EOHTML
        <form action="https://localhost/crap">
            <input name='secure' type='password' />
        </form>
    EOHTML
end
