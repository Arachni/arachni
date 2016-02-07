require 'sinatra'
require 'sinatra/contrib'

ADDRESSES = [
    'tasos@does.not.exist.com',
    'tasos@example.com',
    'john@www.example.com',
    'john32.21d@example.com',
    'a.little.more.unusual@example.com',
    'a.little.more.unusual[at]example[dot]com'
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
