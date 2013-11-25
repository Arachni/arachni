require 'sinatra'
require_relative '../../../components/checks/check_server'

framework.checks[:common_files].filenames.each do |name|
    get( "/#{name}" ) { 'stuff' }
end

get( '/' ) {}
