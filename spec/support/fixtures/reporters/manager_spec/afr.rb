=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::AFR < Arachni::Reporter::Base
    def run
        File.open( "afr", "w" ) {}
    end
end
