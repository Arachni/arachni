=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionGroup

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Options::Error
    end

    class <<self

        # @return   [Hash]
        #   Specified default values for attribute readers.
        def defaults
            @defaults ||= {}
        end

        # Sets default values for attribute readers, when an attribute reader
        # returns `nil` the default values will be returned instead.
        #
        # @param    [Hash]  default_values
        #   Default values for attributes.
        def set_defaults( default_values )
            defaults.merge! default_values

            # Set the specified default values as overrides to the attribute
            # readers.
            defaults.each do |ivar, value|
                define_method "#{ivar}=" do |v|
                    instance_variable_set( "@#{ivar}".to_sym, v.nil? ? value : v)
                end
            end

            defaults
        end

        def inherited( child )
            Options.register_group child
        end
    end

    def initialize
        defaults.each do |k, v|
            send "#{k}=", v
        end
    end

    def to_rpc_data
        to_h.my_stringify_keys(false)
    end

    # @return   [Hash]
    #   Values for all attribute accessors which aren't the defaults.
    def to_h
        h = {}
        instance_variables.each do |ivar|
            method = normalize_ivar( ivar )
            sym    = method.to_sym
            value  = instance_variable_get( ivar )

            next if !respond_to?( "#{method}=" )

            h[sym] = value
        end
        h
    end
    def to_hash
        to_h
    end

    # @return   [Hash]
    #   Hash of errors with the name of the invalid options as the keys.
    #
    # @abstract
    def validate
        {}
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        to_h.hash
    end

    # @param    [Hash]  options
    #   Data to use to update the group's attributes.
    #
    # @return   [OptionGroup]
    #   `self`
    def update( options )
        options.to_hash.each { |k, v| send( "#{k}=", v ) }
        self
    end

    # @param    [OptionGroup]  other
    #
    # @return   [OptionGroup]
    #   `self`
    def merge( other )
        update( other.to_h )
    end

    # @return   (see .defaults)
    def defaults
        self.class.defaults
    end

    def self.attr_accessor( *vars )
        attributes.concat( vars )
        super( *vars )
    end

    def self.attributes
        @attributes ||= []
    end

    def attributes
        self.class.attributes
    end

    private

    def normalize_ivar( ivar )
        ivar.to_s.gsub( '@', '' )
    end
end
end
