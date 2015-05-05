require 'sinatra'

def handler_response_1
    "Random #{rand( 999 ).to_s} bits #{rand( 999 ).to_s} go #{rand( 999 ).to_s} here #{rand( 999 ).to_s}"
end

def handler_response_2
    "Other #{rand( 999 ).to_s} stuff #{rand( 999 ).to_s} are #{rand( 999 ).to_s} here #{rand( 999 ).to_s}"
end

def handler_response_3
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s +
        '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end

get '/not' do
    'This is not a custom 404, watch out.'
end

get '/static/*' do
    'This is a custom 404, try to catch it. ;)'
end

get '/dynamic/*' do
    'This is a custom 404 which includes the requested resource, try to catch it. ;)' +
        '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end

get '/random/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s
end

get '/combo/*' do
    handler_response_1
end

get '/advanced/sensitive-ext/:filename' do |filename|
    name, ext = filename.split( '.', 2 )

    if filename == 'blah.html'
        'Found, all good!'
    elsif name == 'blah' && ext != 'html'
        handler_response_1
    else
        handler_response_2
    end
end
