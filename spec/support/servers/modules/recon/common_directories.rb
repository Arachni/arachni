require 'sinatra'
require_relative '../module_server'

current_module.directories.each { |name| get( "/#{name}/" ) { name } }

get( '/' ) {}
