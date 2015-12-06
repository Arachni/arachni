require 'sinatra'
require_relative '../check_server'

get '/' do
    <<-HTML
        <a href="/some_directory/">Hit me</a>
    HTML
end

get( '/some_directory/' ){}

current_check.formats.each do |format|
    path = format.gsub( '[name]', 'some_directory' )
    get '/' + path do
        path
    end
end
