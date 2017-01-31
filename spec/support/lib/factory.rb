=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Factory
class <<self

    # Clears all instructions and aliases.
    def reset
        @instructions = {}
        @aliases      = {}
    end

    # Defines instruction on how to create a given object.
    #
    # There are 2 ways to define a factory instruction:
    #
    #   * Using a `generator` block to return an object.
    #   * Using the `options` to generate an object.
    #
    # @param    [Symbol]    object_name     Name of the object.
    # @param    [Hash]    options   Generation options.
    # @option   options [Class] :class
    #   Class to instantiate.
    # @option   options [Hash] :options
    #   Options to use to instantiate the `:class`.
    def define( object_name, options = {}, &generator )
        @instructions[object_name] = {
            options:   options.dup,
            generator: generator
        }
    end

    # @param    [Symbol]    object_name     Name of the object.
    # @param    []  args
    #   If a `generator` block has been provided via {#define}, those arguments
    #   will be passed to it.
    #
    #   If `:options` have been passed to {#define}, the `args` will be merged
    #   with them before instantiating the object.
    def create( object_name, *args )
        ensure_defined( object_name )

        instructions = instructions_for( object_name )

        if instructions[:generator]
            instructions[:generator].call( *args )
        elsif (options = instructions[:options]).include? :class
            options[:class].new( options[:options].merge( args.first || {} ) )
        end
    end

    # @param    [Symbol]    object_name     Name of the object.
    # @return   [Hash]  Instantiation options passed to {#define}.
    def options_for( object_name )
        instructions_for( object_name )[:options][:options].freeze
    end

    # @note {#create} helper.
    #
    # @param    [Symbol]    object_name     Name of the object.
    # @return   [Object]    Instantiated object.
    def []( object_name )
        create object_name
    end

    # @param    [Symbol]    object_name
    #   Name of the new object.
    # @param    [Symbol]    existing_object_name
    #   Name of the existing object.
    def alias( object_name, existing_object_name )
        ensure_defined( existing_object_name )
        @aliases[object_name] = existing_object_name
    end

    # @param    [Symbol]    object_name Object to delete.
    def delete( object_name )
        @instructions.delete object_name
    end

    # @param    [Symbol]    object_name Alias to delete.
    def unalias( object_name )
        @aliases.delete object_name
        nil
    end

    # @param    [Symbol]    object_name
    #   Name of the new object.
    # @return   [Bool]
    #   `true` if instructions have been {#defined} for the `object_name`,
    #   `false` otherwise.
    def defined?( object_name )
        !!instructions_for( object_name ) rescue false
    end

    private

    def instructions_for( object_name )
        instructions = @instructions[object_name] || @instructions[@aliases[object_name]]
        return instructions if instructions

        fail ArgumentError, "Factory '#{object_name}' not defined."
    end

    def ensure_defined( object_name )
        !!instructions_for( object_name )
    end
end
reset

end
