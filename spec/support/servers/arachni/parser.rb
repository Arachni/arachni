require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    response.set_cookie( "cookie_input", {
        :value => "cookie_val",
        :secure   => true,
        :httponly => true
    })

    response.set_cookie( "cookie_input2", {
        :value => "cookie_val2",
        :httponly => false
    })
<<EOHTML
<html>
    <head>
        <meta http-equiv="Set-Cookie" content="http_equiv_cookie_name=http_equiv_cookie_val; secure; httponly">
    </head>
    <body>

        <a href="/link?link_input=link_val">Blah</a>

        <form method="post" action="/form" name="my_form">
            <p>
              <input type="text" name="form_input_1" value="form_val_1">
              <input type="text" name="form_input_2" value="form_val_2">
              <input type="submit">
            </p>
        </form>

        <form method="get" action="/form_2" name="my_form_2">
            <input type="text" name="form_2_input_1" value="form_2_val_1">

    </body>
</html>
EOHTML
end

get '/with_nonce' do
    cookies['stuff'] = 'blah'

    <<HTML
    <a href="#/?stuff=blah">DOM link</a>

    <form method="post" action="/form" name="my_form">
        <p>
            <input type="text" name="form_input_1" value="form_val_1">
            <input type="hidden" name="nonce" value="#{rand(999)}">
        </p>
    </form>

    <form method="post" action="/form" name="my_form2">
        <p>
            <input type="text" name="form_input_2" value="form_val_2">
            <input type="hidden" name="nonce2" value="#{rand(999)}">
        </p>
    </form>
HTML
end

get '/with_base' do
<<EOHTML
<html>
    <head>
        <base href="http://#{env['HTTP_HOST']}/this_is_the_base/" />
    </head>
    <body>
        <a href="link_with_base?link_input=link_val">Blah with base</a>
    </body>
</html>
EOHTML
end
