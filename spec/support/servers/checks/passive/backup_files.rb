require 'sinatra'
require_relative '../check_server'

get '/' do
    <<-HTML
        <a href="/some_filename.php">Hit me</a>
    HTML
end

get( '/some_filename.php' ){}

current_check.formats.each do |format|
    path = format.gsub( '[name]', 'some_filename' ).gsub( '[extension]', 'php' )
    get '/' + path do
        path
    end
end
