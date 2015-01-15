=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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
    include Capabilities::Analyzable

    INVALID_INPUT_DATA     = [ "\0" ]
    ENCODE_CHARACTERS      = ["\n", "\r"]
    ENCODE_CHARACTERS_LIST = ENCODE_CHARACTERS.join

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
    def each_mutation( payload, options = {}, &block )
        parameter_names = options.delete( :parameter_names )
        super( payload, options, &block )

        return if !parameter_names

        if !valid_input_name_data?( payload )
            print_debug_level_2 'Payload not supported as input name by' <<
                                    " #{audit_id}: #{payload.inspect}"
            return
        end

        elem = self.dup
        elem.affected_input_name = FUZZ_NAME
        elem.inputs = { payload => FUZZ_NAME_VALUE }
        yield elem
    end

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
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
            return str if !ENCODE_CHARACTERS.find { |c| str.include? c }

            ::URI.encode( str, ENCODE_CHARACTERS_LIST )
        end

        def decode( header )
            ::URI.decode( header.to_s )
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
