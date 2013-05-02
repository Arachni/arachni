require 'sinatra'

get '/' do
    <<-EOHTML
        <a href="/captcha">Captcha</a>
        <a href="/empty">Empty</a>
        <a href="/irrelevant">Irrelevant</a>
    EOHTML
end

get '/captcha' do
    <<-EOHTML
        <form>
            <input name='CapTcha-32-Some_stuff' />
        </form>
    EOHTML
end

get '/empty' do
    ''
end

get '/irrelevant' do
    <<-EOHTML
        Random crap here...
    EOHTML
end
