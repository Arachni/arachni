require 'sinatra'
require_relative '../check_server'

current_check.filenames.each { |name| get( "/#{name}" ) { name } }

get( '/' ) {}
