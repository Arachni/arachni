require 'sinatra'
require_relative '../module_server'

current_module.filenames.each { |name| get( "/#{name}" ) { name } }

get( '/' ) {}
