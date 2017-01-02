=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

def name_from_filename
    File.basename( caller.first.split( ':' ).first, '_spec.rb' )
end

def spec_path
    File.expand_path( File.dirname( File.absolute_path( __FILE__ )  ) + '/../../' ) + '/'
end

def support_path
    "#{spec_path}support/"
end

def fixtures_path
    "#{support_path}fixtures/"
end
