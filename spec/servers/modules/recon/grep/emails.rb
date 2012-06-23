require 'sinatra'
require 'sinatra/contrib'

ADDRESSES = [
    'tasos@blah.com',
    'john@foo.blah.com',
    'john32.21d@foo.blah.com',
    'a.little.more.unusual@dept.example.com'
]

ADDRESSES.each.with_index  do |address, i|
    get "/#{i}" do
        address
    end
end

get '/' do
    ADDRESSES.map.with_index do |type, i|
        "<a href=\"#{i}\">#{i}</a> "
    end.join
end
