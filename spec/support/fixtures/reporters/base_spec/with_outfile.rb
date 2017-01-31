=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::WithOutfile < Arachni::Reporter::Base
    def run
    end

    def self.info
        super.merge( options: [ Arachni::Reporter::Options.outfile('.stuff') ] )
    end
end
