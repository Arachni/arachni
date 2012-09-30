require 'sinatra'
require 'sinatra/contrib'

get '/' do
    response.set_cookie( "cookie", {
        value:  "value",
        secure: false
    })
    response.set_cookie( "cookie2", {
        value:  "value2",
        secure: false
    })
    response.set_cookie( "cookie3", {
        value:  "value3",
        secure: true
    })
    response.set_cookie( "cookie4", {
        value:  "value4",
        secure: true
    })
end
