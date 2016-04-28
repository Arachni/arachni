require 'yaml'
require 'sinatra'
require 'sinatra/streaming'

get '/' do
    params.to_s
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

get '/refreshable' do
    <<HTML
    <a href="/refreshable?param_name=stuff">Irrelevant</a>
    <a href="/link?param_name=stuff&nonce=#{rand(999)}">Refreshable</a>
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
    <a href="/refreshable?param_name=stuff">Irrelevant</a>
    <a href="/link?param_name=stuff&nonce=#{rand(999)}">Refreshable</a>
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
    <a href="/refreshable?param_name=stuff">Irrelevant</a>
    <a href="/link?param_name=stuff&nonce=#{rand(999)}">Refreshable</a>
HTML
end
