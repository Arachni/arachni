=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::WithOutfile < Arachni::Reporter::Base
    def run
    end

    def self.info
        super.merge( options: [ Arachni::Reporter::Options.outfile('.stuff') ] )
    end
end
