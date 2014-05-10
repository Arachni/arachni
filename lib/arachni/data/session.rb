=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Data

# Data for {Arachni::Session}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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

