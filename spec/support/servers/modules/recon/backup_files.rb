require 'sinatra'
require_relative '../module_server'

get '/' do
    <<-HTML
        <a href="/some_filename.php">Hit me</a>
    HTML
end

%w(some_filename.php).each do |filename|
    get '/' + filename do
        filename
    end

    current_module.extensions.each do |ext|
        path = ext % filename
        get '/' + path do
            path
        end
    end

    current_module.extensions.each do |ext|
        path = ext % filename.split( '.' ).first
        get '/' + path do
            path
        end
    end
end
