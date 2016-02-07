require 'yaml'
require 'sinatra'
set :logging, false

IGNORE = %w(HTTP_VERSION HTTP_HOST HTTP_ACCEPT_ENCODING HTTP_USER_AGENT HTTP_ACCEPT HTTP_ACCEPT_LANGUAGE)

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
