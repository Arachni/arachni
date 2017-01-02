=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# The base class for all options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Arachni::Component::Options::Base

    # @return   [Symbol]    Name.
    attr_reader   :name

    # @return   [String]    Description.
    attr_reader   :description

    # @return   [Object]    Default value.
    attr_reader   :default

    # @return   [Object]    Assigned value.
    attr_accessor :value

    # Initializes a named option with the supplied attribute array.
    # The array is composed of three values.
    #
    # @param    [Symbol]    name
    #   Name of the option.
    # @param    [Hash]     options
    #   Option attributes.
    # @option   options [String, Symbol]    :name
    #   {#name Name} for this option.
    # @option   options [String]    :description
    #   {#name Description} for this option.
    # @option   options [Bool]    :required (false)
    #   Is this option {#required?}.
    # @option   options [Object]    :default
    #   {#name Default value} for this option.
    # @option   options [Object]    :value
    #   {#value Value} for this option.
    def initialize( name, options = {} )
        options = options.dup

        @name        = name.to_sym
        @required    = !!options.delete(:required)
        @description = options.delete(:description)
        @default     = options.delete(:default)
        @value       = options.delete(:value)

        return if options.empty?
        fail ArgumentError, "Unknown options: #{options.keys.join( ', ' )}"
    end

    # Returns true if this is a required option.
    #
    # @return   [Bool]
    #   `true` if the option is required, `false` otherwise.
    def required?
        @required
    end

    # @return   [Bool]
    #   `true` if the option value is valid, `false` otherwise.
    def valid?
        !missing_value?
    end

    # @return   [Bool]
    #   `true` if the option is {#required?} but has no {#value},
    #   `false` otherwise.
    def missing_value?
        required? && effective_value.nil?
    end

    # @return   [Object]
    #   Convert the user-provided {#value} (which will usually be a
    #   user-supplied String) to the desired Ruby type.
    #
    # @abstract
    def normalize
        effective_value
    end

    # @return   [Object]
    #   {#value} or {#default}.
    def effective_value
        @value || @default
    end

    # @return   [Symbol]
    #   Type identifying the option.
    #
    # @abstract
    def type
        :abstract
    end

    # @return    [Hash]
    #   {#name} => {#normalize}
    def for_component
        { name => normalize }
    end

    # @return    [Hash]
    def to_h
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' ).to_sym] = instance_variable_get( var )
        end
        hash.merge( type: type )
    end
    alias :to_hash :to_h

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        to_h.merge( class: self.class.to_s ).my_stringify_keys
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Base]
    def self.from_rpc_data( data )
        data.delete('type')
        data.delete('class')
        name = data.delete('name')

        new name, data.my_symbolize_keys(false)
    end

    def ==( option )
        hash == option.hash
    end

    def hash
        to_h.hash
    end

end
