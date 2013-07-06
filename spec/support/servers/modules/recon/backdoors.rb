require 'sinatra'
require_relative '../module_server'

current_module.filenames.each { |filename| get( "/#{filename}" ) { filename } }
