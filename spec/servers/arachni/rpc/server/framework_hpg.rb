require 'sinatra'
set :logging, false

configure do
    @@paths ||= (0..50).to_a.map do |i|
        "/vulnerable?vulnerable_#{i.to_s}=stuff#{i.to_s}"
    end
end

@@paths.each.with_index do
    |path, i|
    get( "/#{i}"){ "<a href='#{path}'>Vulnerable</a>" }
end

get '/' do
    @@paths.map { |path| "<a href='#{path}'>Vulnerable</a>" }.join( '<br/>' )
end

get '/vulnerable' do
    params.values.to_s
end
