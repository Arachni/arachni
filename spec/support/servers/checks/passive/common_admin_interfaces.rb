require 'sinatra'
require_relative '../check_server'

current_check.resources.each { |name| get( "/#{name}" ) { name } }

get( '/' ) {}
