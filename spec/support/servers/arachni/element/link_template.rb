require 'yaml'
require 'sinatra'
require 'sinatra/streaming'

get '/param/:value' do |value|
    { 'param' => value }.to_yaml
end

get '/name1/:value1/name2/:value2' do |value1, value2|
    { 'name1' => value1, 'name2' => value2 }.to_yaml
end

get '/param/:value/buffered' do |value|
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print ({ 'param' => value }.to_yaml)
        out.print 'END_PARAMS'

        2_000.times do |i|
            out.print "Blah"
        end
    end
end

get '/param/:value/line_buffered' do |value|
    stream do |out|
        2_000.times do |i|
            out.puts "Blah"
        end

        out.puts 'START_PARAMS'
        out.puts ({ 'param' => value }.to_yaml)
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end
