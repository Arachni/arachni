=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::AFR < Arachni::Report::Base
    def run
        File.open( "afr", "w" ) {}
    end
end
