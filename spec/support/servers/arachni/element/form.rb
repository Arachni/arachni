require 'yaml'
require 'sinatra'
set :logging, false

get '/' do
    env['REQUEST_METHOD'].downcase + params.to_s
end

get '/submit' do
    params.to_hash.to_yaml
end

get '/sleep' do
    sleep 2
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
    EOHTML
end

post '/' do
    env['REQUEST_METHOD'].downcase + env['rack.request.form_hash'].to_s
end

post '/submit' do
    params.to_hash.to_yaml
end

post '/sleep' do
    sleep 2
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
    EOHTML
end

get '/forms' do
<<EOHTML
<html>
    <body>
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

get '/refreshable' do
    <<HTML
    <form method="post" action="/refreshable" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
        </p>
    </form>

    <form method="post" action="/refreshable" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
            <input type="hidden" name="nonce" value="#{rand(999)}">
        </p>
    </form>
HTML
end

get '/with_nonce' do
    <<HTML
    <form method="post" action="/form" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
        </p>
    </form>

    <form method="post" action="/form" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
            <input type="hidden" name="nonce" value="#{rand(999)}">
        </p>
    </form>
HTML
end

get '/get_nonce' do
    params['nonce']
end
