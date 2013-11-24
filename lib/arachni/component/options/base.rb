=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# The base class for all options.
#
###
class Arachni::Component::Options::Base

    #
    # The name of the option.
    #
    attr_accessor :name

    #
    # The description of the option.
    #
    attr_reader :desc

    #
    # The default value of the option.
    #
    attr_reader :default

    #
    # The list of potential valid values
    #
    attr_accessor :enums


    #
    # Initializes a named option with the supplied attribute array.
    # The array is composed of three values.
    #
    # attrs[0] = required (boolean type)
    # attrs[1] = description (string)
    # attrs[2] = default value
    # attrs[3] = possible enum values
    #
    # @param    [String]    name    the name of the options
    # @param    [Array]     attrs   option attributes
    #
    def initialize( name, attrs = [] )
        @name     = name
        @required = attrs[0] || false
        @desc     = attrs[1]
        @default  = attrs[2]
        @enums    = [ *(attrs[3]) ].map { |x| x.to_s }
    end

    #
    # Returns true if this is a required option.
    #
    def required?
        @required
    end

    #
    # Returns true if the supplied type is equivalent to this option's type.
    #
    def type?( in_type )
        type == in_type
    end

    #
    # If it's required and the value is nil or empty, then it's not valid.
    #
    def valid?( value )
        ( required? && ( value.nil? || value.to_s.empty? ) ) ? false : true
    end

    #
    # Returns true if the value supplied is nil and it's required to be
    # a valid value
    #
    def empty_required_value?( value )
        required? && value.nil?
    end

    #
    # Normalizes the supplied value to conform with the type that the option is
    # conveying.
    #
    def normalize( value )
        value
    end

    def type
        'abstract'
    end

    #
    # Converts the Options object to hash
    #
    # @return    [Hash]
    #
    def to_h
        hash = {}
        self.instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = self.instance_variable_get( var )
        end
        hash.merge( 'type' => type )
    end

    def ==( opt )
        to_h == opt.to_h
    end

    protected
    attr_writer :required, :desc, :default # :nodoc:

end
