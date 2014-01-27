require 'sinatra'
require_relative '../check_server'

current_check.filenames.each { |filename| get( "/#{filename}" ) { filename } }
