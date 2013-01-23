require 'sinatra'
require File.dirname( __FILE__ ) + '/../../../modules/module_server'

framework.modules[:common_files].filenames.each do |name|
    get( "/#{name}" ) { 'stuff' }
end

get( '/' ) {}
