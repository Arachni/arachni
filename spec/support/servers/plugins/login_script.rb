require 'sinatra'
require 'sinatra/contrib'

get '/' do
    cookies[:success] ||= 'false'

    if cookies[:success] == 'true'
        <<-HTML
            <a href='/congrats'>Hi there logged-in user!</a>
        HTML
    end
end

