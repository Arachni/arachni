require 'sinatra'
require 'sinatra/contrib'

get '/' do
    response.set_cookie( 'cookie', {
        value:  'value',
        domain: '.localhost'
    })
    response.set_cookie( 'cookie2', {
        value:  'value2',
        domain: 'localhost'
    })
    response.set_cookie( 'cookie3', {
        value:  'value3'
    })
    response.set_cookie( 'cookie4', {
        value:  'value4'
    })
end
