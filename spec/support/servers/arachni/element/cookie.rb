require 'yaml'
require 'sinatra'
require 'sinatra/streaming'
require 'sinatra/contrib'

set :logging, false

get '/' do
    env['REQUEST_METHOD'].downcase + params.to_s
end

get '/submit' do
    cookies.to_hash.to_yaml
end

get '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print cookies.to_hash.to_yaml
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
        out.puts cookies.to_hash.to_yaml
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end

get '/sleep' do
    sleep 2
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{cookies[:input]}
    EOHTML
end

get '/set_cookie' do
    cookies['my-cookie'] = 'my-val'
    ''
end

get '/with_other_elements' do
    cookies['mycookie'] ||= 'cookie val'
    <<HTML
    <a href='?link_name=link_val'>A link</a>

    <form action='?form_name=form_val'>
        <input name='input' />
        <input name='input2' />
    </form>
HTML
end
