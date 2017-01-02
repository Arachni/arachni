=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Data

# Data for {Arachni::Session}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Session

    # @return   [Hash]
    attr_reader :configuration

    def initialize
        @configuration = {}
    end

    def statistics
        {}
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/configuration", Marshal.dump( @configuration ) )
    end

    def self.load( directory )
        session = new
        session.configuration.merge! Marshal.load( IO.binread( "#{directory}/configuration" ) )
        session
    end

    def clear
        @configuration.clear
    end

end

end
end

