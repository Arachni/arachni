require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    params.map { |k, v| k.to_s + v.to_s }.join( "\n" )
end

get '/sleep' do
    sleep 2
<<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
end
