require 'sinatra'

use Rack::Auth::Basic do |username, password|
    [username, password] == %w(admin pass)
end

get '/' do
    'authenticated!'
end
