require 'sinatra'

use Rack::Auth::Basic do |username, password|
    [username, password] == %w(admin3434234342 pass)
end

get '/' do
    'authenticated!'
end
