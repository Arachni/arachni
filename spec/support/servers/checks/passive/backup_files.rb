require 'sinatra'
require_relative '../check_server'

get '/' do
    s = <<-HTML
        <a href="/some_filename.php">Hit me</a>
    HTML

    current_check::IGNORE_EXTENSIONS.each do |extension|
        s << <<-HTML
            <a href="/some_media.#{extension}">Hit media</a>
        HTML
    end

    s
end

get( '/some_filename.php' ){}

current_check::IGNORE_EXTENSIONS.each do |extension|
    get( '/some_media.' + extension ){}
end

current_check.formats.each do |format|
    path = format.gsub( '[name]', 'some_filename' ).gsub( '[extension]', 'php' )
    get '/' + path do
        path
    end

    current_check::IGNORE_EXTENSIONS.each do |extension|
        path = format.gsub( '[name]', 'some_media' ).gsub( '[extension]', extension )
        get '/' + path do
            path
        end
    end
end
