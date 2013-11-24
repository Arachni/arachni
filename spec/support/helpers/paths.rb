=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
