require 'sinatra'
require_relative '../check_server'

current_check.acceptable.each { |code| get( "/#{code}" ) { status code; code.to_s + rand( 9999 ).to_s } }
current_check.acceptable.each { |code| get( "/blah/#{code}" ) { status code; code.to_s + rand( 9999 ).to_s } }
