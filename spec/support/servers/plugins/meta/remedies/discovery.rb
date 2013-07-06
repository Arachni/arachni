require 'sinatra'
require_relative '../../../modules/module_server'

framework.modules[:common_files].filenames.each do |name|
    get( "/#{name}" ) { 'stuff' }
end

get( '/' ) {}
