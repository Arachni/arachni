=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Error < Arachni::Reporter::Base

    def run
        fail
    end

    def self.info
        super.merge( options: [ Options.outfile( 'foo' ) ] )
    end
end
