require 'sinatra'
require_relative '../module_server'

current_module.acceptable.each { |code| get( "/#{code}" ) { status code; code.to_s + rand( 9999 ).to_s } }
current_module.acceptable.each { |code| get( "/blah/#{code}" ) { status code; code.to_s + rand( 9999 ).to_s } }
