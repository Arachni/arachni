require 'sinatra'
require 'sinatra/streaming'

post '/submit' do
    request.body.read
end

post '/submit/buffered' do
    stream do |out|
        2_000.times do |i|
            out.print "Blah"
        end

        out.print 'START_PARAMS'
        out.print request.body.read
        out.print 'END_PARAMS'

        2_000.times do |i|
            out.print "Blah"
        end
    end
end

post '/submit/line_buffered' do
    stream do |out|
        2_000.times do |i|
            out.puts "Blah"
        end

        out.puts 'START_PARAMS'
        out.puts request.body.read
        out.puts 'END_PARAMS'

        2_000.times do |i|
            out.puts "Blah"
        end
    end
end
