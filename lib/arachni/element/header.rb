=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents an auditable request header element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Header < Base

    # Load and include all form-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::Auditable
    include Arachni::Element::Capabilities::Auditable::Buffered
    include Arachni::Element::Capabilities::Auditable::LineBuffered
    include Arachni::Element::Capabilities::Submittable
    include Arachni::Element::Capabilities::Inputtable
    include Arachni::Element::Capabilities::Analyzable

    # Header-specific overrides.
    include Capabilities::Mutable
    include Capabilities::Inputtable

    ENCODE_CHARACTERS      = ["\n", "\r"]
    ENCODE_CHARACTERS_LIST = ENCODE_CHARACTERS.join

    ENCODE_CACHE = Arachni::Support::Cache::LeastRecentlyPushed.new( 1_000 )
    DECODE_CACHE = Arachni::Support::Cache::LeastRecentlyPushed.new( 1_000 )

    def initialize( options )
        super( options )

        self.inputs = options[:inputs]

        @default_inputs = self.inputs.dup.freeze
    end

    def simple
        @inputs.dup
    end

    # @return   [String]
    #   Header name.
    def name
        @inputs.first.first
    end

    # @return   [String]
    #   Header value.
    def value
        @inputs.first.last
    end

    class <<self
        def encode( str )
            str = str.to_s

            ENCODE_CACHE.fetch( str ) do
                if !ENCODE_CHARACTERS.find { |c| str.include? c }
                    str
                else
                    ::URI.encode( str, ENCODE_CHARACTERS_LIST )
                end
            end
        end

        def decode( header )
            header = header.to_s

            DECODE_CACHE.fetch( header ) do
                ::URI.decode( header )
            end
        end
    end

    def encode( header )
        self.class.encode( header )
    end

    def decode( header )
        self.class.decode( header )
    end

    private

    def http_request( opts, &block )
        http.header( @action, opts, &block )
    end

end
end

Arachni::Header = Arachni::Element::Header
