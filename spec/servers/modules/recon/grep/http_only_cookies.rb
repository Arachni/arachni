require 'sinatra'
require 'sinatra/contrib'

get '/' do
    response.set_cookie( "cookie", {
        value:    "value",
        httponly: false
    })
    response.set_cookie( "cookie2", {
        value:    "value2",
        httponly: false
    })
    response.set_cookie( "cookie3", {
        value:    "value3",
        httponly: true
    })
    response.set_cookie( "cookie4", {
        value:    "value4",
        httponly: true
    })
end
