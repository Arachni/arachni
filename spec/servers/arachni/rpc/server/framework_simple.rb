require 'sinatra'
set :logging, false

get '/' do
end

get '/crawl' do
    <<-EOHTML
    <a href='/sleep'></a>
    EOHTML
end

get '/sleep' do
    sleep 10
end

get '/restrict_to_elements' do
    <<-EOHTML
    <a href='/restrict_to_elements/to_audit?vulnerable_1=stuff1'>To audit</a>
    <a href='/restrict_to_elements/to_skip?vulnerable_2=stuff2'>To skip</a>
    EOHTML
end

get '/restrict_to_elements/to_audit' do
    params[:vulnerable_1]
end

get '/restrict_to_elements/to_skip' do
    params[:vulnerable_2]
end
