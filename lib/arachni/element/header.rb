=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents an auditable request header element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Header < Base
    include Capabilities::Analyzable

    INVALID_INPUT_DATA = [ "\0" ]

    def initialize( options )
        super( options )

        self.inputs = options[:inputs]

        @default_inputs = self.inputs.dup.freeze
    end

    def simple
        @inputs.dup
    end

    # Overrides {Capabilities::Mutable#each_mutation} to handle header-specific
    # limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( injection_str, opts = {}, &block )
        flip = opts.delete( :param_flip )
        super( injection_str, opts, &block )

        return if !flip

        try_input do
            elem = self.dup
            elem.affected_input_name = 'Parameter flip'
            elem.inputs = { injection_str => seed }
            yield elem
        end
    end

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

    # @return   [String]    Header name.
    def name
        @inputs.first.first
    end

    # @return   [String]    Header value.
    def value
        @inputs.first.last
    end

    class <<self
        def encode( header )
            ::URI.encode( header, "\r\n" )
        end

        def decode( header )
            ::URI.decode( header )
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
