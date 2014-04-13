=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# The base class for all options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Base

    # The name of the option.
    attr_reader   :name

    # The description of the option.
    attr_reader   :description

    # The default value of the option.
    attr_reader   :default

    # The value of the option.
    attr_accessor :value

    # Initializes a named option with the supplied attribute array.
    # The array is composed of three values.
    #
    # @param    [Symbol]    name    the name of the options
    # @param    [Hash]     options   option attributes
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

    # If it's required and the value is nil or empty, then it's not valid.
    def valid?
        !missing_value?
    end

    # Returns true if the value supplied is `nil` and it's required to be
    # a valid value
    def missing_value?
        required? && effective_value.nil?
    end

    def normalize
        effective_value
    end

    def effective_value
        @value || @default
    end

    def type
        'abstract'
    end

    # @return    [Hash] `name` => `value`
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

    def ==( option )
        to_h == option.hash
    end

    def hash
        to_h.hash
    end

end
