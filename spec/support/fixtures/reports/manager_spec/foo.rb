=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::Foo < Arachni::Report::Base

    def run
        File.open( "foo", "w" ) {}
    end

    def self.info
        super.merge( options: [ Options.outfile( 'foo' ) ] )
    end
end
