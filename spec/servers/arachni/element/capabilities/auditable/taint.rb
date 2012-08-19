require 'sinatra'
require 'sinatra/contrib'
set :logging, false

get '/' do
    <<-EOHTML
    <a href='?input=blah'>Inject here</a>
    #{params[:input]}
EOHTML
end
