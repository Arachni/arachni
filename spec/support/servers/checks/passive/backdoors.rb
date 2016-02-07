require 'sinatra'
require_relative '../check_server'

get( '/' ){}
current_check.filenames.each { |filename| get( "/#{filename}" ) { filename } }
