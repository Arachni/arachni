require 'sinatra'
require_relative '../check_server'

current_check.directories.each { |name| get( "/#{name}/" ) { name } }

get( '/' ) {}
