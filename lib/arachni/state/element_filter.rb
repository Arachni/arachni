=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class State

# Stores and provides access to the state of the {Arachni::ElementFilter}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ElementFilter

    # @return   [Support::LookUp::HashSet]
    attr_reader :forms

    # @return   [Support::LookUp::HashSet]
    attr_reader :links

    # @return   [Support::LookUp::HashSet]
    attr_reader :cookies

    def initialize
        @forms   = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @links   = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @cookies = Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def statistics
        {
            forms:   forms.size,
            links:   links.size,
            cookies: cookies.size
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/sets", Marshal.dump( self ) )
    end

    def self.load( directory )
        Marshal.load( IO.binread( "#{directory}/sets" ) )
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        [@forms.hash, @links.hash, @cookies.hash].hash
    end

    def clear
        forms.clear
        links.clear
        cookies.clear
    end

end

end
end
