=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

class Header < Base
    include Capabilities::Auditable

    def initialize( options )
        super( options )

        self.method = :get
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
    def each_mutation( injection_str, opts = {} )
        flip = opts.delete( :param_flip )

        super( injection_str, opts ) do |mutation|
            # Headers don't support nulls.
            next if (mutation.format & Format::NULL) != 0
            yield mutation
        end

        return if !flip
        elem = self.dup

        # when under HPG mode element auditing is strictly regulated
        # and when we flip params we essentially create a new element
        # which won't be on the whitelist
        elem.override_instance_scope

        elem.affected_input_name = 'Parameter flip'
        elem.inputs  = { injection_str => seed }
        yield elem
    end

    # @return   [String]    Header name.
    def name
        @inputs.first.first
    end

    # @return   [String]    Header value.
    def value
        @inputs.first.last
    end

    def self.encode( header )
        ::URI.encode( header, "\0\r\n" )
    end
    def encode( header )
        self.class.encode( header )
    end

    def self.decode( header )
        ::URI.decode( header )
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
