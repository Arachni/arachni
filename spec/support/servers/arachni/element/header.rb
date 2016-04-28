require 'yaml'
require 'sinatra'
require 'sinatra/streaming'

set :logging, false

IGNORE = %w(HTTP_VERSION HTTP_HOST HTTP_ACCEPT_ENCODING HTTP_USER_AGENT
    HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE HTTP_X_ARACHNI_SCAN_SEED)

def submitted
    h = {}
    env.select { |k, v| k.start_with?( 'HTTP_' ) && !IGNORE.include?( k ) }.each do |k, v|
        h[k.gsub( 'HTTP_', '' ).downcase] = v
    end
    h
end

get '/' do
    submitted.to_s
end

get '/submit' do
    submitted.to_hash.to_yaml
end

get '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print submitted.to_hash.to_yaml
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
        out.puts submitted.to_hash.to_yaml
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end
