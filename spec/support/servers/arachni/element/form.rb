require 'yaml'
require 'sinatra'
require 'sinatra/streaming'

set :logging, false

get '/' do
    env['REQUEST_METHOD'].downcase + params.to_s
end

post '/' do
    env['REQUEST_METHOD'].downcase + env['rack.request.form_hash'].to_s
end

get '/submit' do
    params.to_hash.to_yaml
end

get '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print params.to_hash.to_yaml
        out.print 'END_PARAMS'

        2_000.times do |i|
            out.print "Blah"
        end
    end
end

get '/submit/line_buffered' do
    stream do |out|
        2_000.times do |i|
            out.puts "Blah"
        end

        out.puts 'START_PARAMS'
        out.puts params.to_hash.to_yaml
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end

post '/submit' do
    params.to_hash.to_yaml
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

get '/refreshable_disappear_clear' do
    @@visited = 0
end

get '/refreshable_disappear' do
    @@visited ||= 0
    @@visited  += 1

    next '' if @@visited > 1

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
    <form method="post" action="/get_nonce" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
        </p>
    </form>

    <form method="post" action="/get_nonce" name="my_form">
        <p>
            <input type="text" name="param_name" value="param_value">
            <input type="hidden" name="nonce" value="#{rand(999)}">
        </p>
    </form>
HTML
end

post '/get_nonce' do
    params['nonce']
end
