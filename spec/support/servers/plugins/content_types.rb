require 'sinatra'

TYPES = {
    css:   'text/css',
    png:   'image/png',
    excel: 'application/vnd.ms-excel',
}

get '/' do
    TYPES.keys.map { |k| "<a href='#{k}'></a>" }.join
end

TYPES.each do |k, v|
    get "/#{k}" do
        headers 'Content-Type' => v
    end
end
