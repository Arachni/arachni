require 'sinatra'
require_relative '../../../checks/check_server'

framework.checks[:common_files].filenames.each do |name|
    get( "/#{name}" ) { 'stuff' }
end

get( '/' ) {}
