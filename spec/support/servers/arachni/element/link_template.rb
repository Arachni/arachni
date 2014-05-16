require 'yaml'
require 'sinatra'

get '/param/*' do
    { 'param' => params['splat'].first }.to_yaml
end

get '/name1/*/name2/*' do
    name1, name2 = params['splat']
    { 'name1' => name1, 'name2' => name2 }.to_yaml
end
