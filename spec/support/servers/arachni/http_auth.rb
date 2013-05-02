require 'sinatra'

use Rack::Auth::Basic do |username, password|
  [username, password] == %w(username password)
end

get '/auth' do
    'authenticated!'
end
