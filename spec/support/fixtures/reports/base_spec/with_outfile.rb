=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reports::WithOutfile < Arachni::Report::Base
    def run
    end

    def self.info
        super.merge( options: [ Arachni::Report::Options.outfile('.stuff') ] )
    end
end
