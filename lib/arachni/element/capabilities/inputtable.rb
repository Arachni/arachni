=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Capabilities::Inputtable

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Capabilities::Error

        # On invalid input data.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidData < Error

            # @see Inputtable#valid_input_data?
            # @see Inputtable#valid_input_name?
            #
            # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
            class Name < InvalidData
            end

            # @see Inputtable#valid_input_data?
            # @see Inputtable#valid_input_value?
            #
            # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
            class Value < InvalidData
            end

        end
    end

    INPUTTABLE_CACHE = {
        inputtable_id: Support::Cache::LeastRecentlyPushed.new( 1_000 )
    }

    # Frozen version of {#inputs}, has all the original names and values.
    #
    # @return   [Hash]
    attr_reader :default_inputs

    # @note Can be modified via {#update}, {#[]=} or {#inputs=}.
    #
    # @return   [Hash]
    #   Frozen effective inputs.
    attr_reader :inputs

    # @note Null-bytes will always be encoded.
    #
    # @return   [Array]
    #   List of input names which should have their values submitted in raw
    #   form, without encoding.
    attr_reader :raw_inputs

    def initialize( options )
        super
        @raw_inputs = []
    end

    # @param    [String]    name
    #   Name of the input to check.
    #
    # @return   [Boolean]
    #   `true` if the input `name` is in {#raw_inputs}, `false` otherwise.
    def raw_input?( name )
        @raw_inputs.include? name
    end

    # @note Will convert names to strings.
    #
    # @param  [Array]  raw
    #   Input names whose values should not be encoded during submission.
    #
    # @raise   [Error::InvalidData::Name]
    def raw_inputs=( raw )
        names = raw.map(&:to_s)
        names.each { |name| fail_if_invalid_name( name ) }
        @raw_inputs = raw.map(&:to_s)
    end

    # @note Will convert keys and values to strings.
    #
    # @param  [Hash]  hash
    #   Input data.
    #
    # @raise   [Error::InvalidData::Name]
    # @raise   [Error::InvalidData::Value]
    def inputs=( hash )
        sanitized = {}

        (hash || {}).each do |name, value|
            name  = name.to_s
            value = value.to_s

            fail_if_invalid( name, value )

            sanitized[name.freeze] = value.freeze
        end

        @inputs = sanitized.freeze
    end

    # Checks whether or not the given inputs match the inputs ones.
    #
    # @param    [Hash, Array, String, Symbol]   args
    #   Names of inputs to check (also accepts var-args).
    #
    # @return   [Bool]
    def has_inputs?( *args )
        if (h = args.first).is_a?( Hash )
            h.each { |k, v| return false if self[k] != v }
            true
        else
            keys = args.flatten.compact.map { |a| [a].map(&:to_s) }.flatten
            (@inputs.keys & keys).size == keys.size
        end
    end

    # @return   [Hash]
    #   Returns changes make to the {#inputs}'s inputs.
    def changes
        (@default_inputs.keys | @inputs.keys).inject( {} ) do |h, k|
            if @default_inputs[k] != @inputs[k]
                h[k] = @inputs[k]
            end
            h
        end
    end

    def updated?
        @default_inputs != self.inputs
    end

    # Resets the inputs to their original format/values.
    def reset
        super if defined?( super )
        self.inputs = @default_inputs.rpc_clone
        self.raw_inputs = []
        self
    end

    # Shorthand {#inputs} reader.
    #
    # @param    [#to_s] name
    #   Name.
    #
    # @return   [String]
    def []( name )
        @inputs[name.to_s]
    end

    # Shorthand {#inputs} writer.
    #
    # @param    [#to_s] name
    #   Name.
    # @param    [#to_s] value
    #   Value.
    #
    # @raise   [Error::InvalidData::Name]
    # @raise   [Error::InvalidData::Value]
    def []=( name, value )
        update( name.to_s => value.to_s )
        self[name]
    end

    # @param    [Hash]  hash
    #   Inputs with which to update the {#inputs} inputs.
    #
    # @return   [Auditable]   `self`
    #
    # @raise   [Error::InvalidData::Name]
    # @raise   [Error::InvalidData::Value]
    def update( hash )
        return self if hash.empty?

        self.inputs = @inputs.merge( hash )
        self
    end

    # @param    [String]    name
    #   Name to check.
    #
    # @return   [Bool]
    #   `true` if the name can be carried by the element's inputs, `false`
    #   otherwise.
    #
    # @abstract
    def valid_input_name?( name )
        true
    end

    # @param    [String]    name
    #   Name to check.
    #
    # @return   [Bool]
    #   `true` if `name` is both a {#valid_input_name?} and contains
    #   {#valid_input_data?}.
    def valid_input_name_data?( name )
        valid_input_name?( name ) && valid_input_data?( name )
    end

    # @param    [String]    value
    #   Value to check.
    #
    # @return   [Bool]
    #   `true` if the value can be carried by the element's inputs, `false`
    #   otherwise.
    #
    # @abstract
    def valid_input_value?( value )
        true
    end

    # @param    [String]    value
    #   Value to check.
    #
    # @return   [Bool]
    #   `true` if `value` is both a {#valid_input_value?} and contains
    #   {#valid_input_data?}.
    def valid_input_value_data?( value )
        valid_input_value?( value ) && valid_input_data?( value )
    end

    # @param    [String]    data
    #   Data to check.
    #
    # @return   [Bool]
    #   `true` if the data can be carried by the element's inputs, `false`
    #   otherwise.
    #
    # @abstract
    def valid_input_data?( data )
        true
    end

    # Performs an input operation and silently handles {Error::InvalidData}.
    #
    # @param    [Block] block
    #   Input operation to try to perform.
    #
    # @return   [Bool]
    #   `true` if the operation was successful, `false` otherwise.
    def try_input( &block )
        block.call
        true
    rescue Error::InvalidData => e
        return false if !respond_to?( :print_debug_level_1 )

        print_debug_level_1 e.to_s
        e.backtrace.each { |l| print_debug_level_1 l }
        false
    end

    def dup
        copy_inputtable( super )
    end

    # @return   [String]
    #   Uniquely identifies the {#inputs}.
    def inputtable_id
        Arachni::Element::Capabilities::Inputtable.inputtable_id( inputs, raw_inputs )
    end

    def self.inputtable_id( inputs, raw_inputs )
        INPUTTABLE_CACHE[:inputtable_id].fetch [inputs, raw_inputs] do
            id  = inputs ? inputs.sort_by { |k, _| k }.hash.to_s : ''
            id << ':'
            id << (raw_inputs ? raw_inputs.sort.hash.to_s : '')
        end
    end

    def to_h
        (defined?( super ) ? super : {}).merge(
            inputs:         inputs,
            raw_inputs:     raw_inputs,
            default_inputs: default_inputs
        )
    end

    private

    def fail_if_invalid_name( name )
        if !valid_input_data?( name.to_s )
            fail Error::InvalidData::Name,
                 "Invalid data in input name for #{self.class}: #{name.inspect}"
        end

        if !valid_input_name?( name.to_s )
            fail Error::InvalidData::Name,
                 "Invalid name for #{self.class}: #{name.inspect}"
        end
    end

    def fail_if_invalid_value( value )
        if !valid_input_data?( value.to_s )
            fail Error::InvalidData::Value,
                 "Invalid data in input value for #{self.class}: #{value.inspect}"
        end

        if !valid_input_value?( value.to_s )
            fail Error::InvalidData::Value,
                 "Invalid value for #{self.class}: #{value.inspect}"
        end
    end

    def fail_if_invalid( name, value )
        fail_if_invalid_name( name )
        fail_if_invalid_value( value )
    end

    def copy_inputtable( other )
        other.inputs     = self.inputs.dup
        other.raw_inputs = self.raw_inputs.dup
        other
    end

end

end
end
