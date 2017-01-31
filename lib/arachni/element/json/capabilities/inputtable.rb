=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class JSON
module Capabilities

# Extends {Arachni::Element::Capabilities::Inputtable} with {JSON}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Inputtable
    include Arachni::Element::Capabilities::Inputtable

    # Overrides {Arachni::Element::Capabilities::Inputtable#inputs=} to allow
    # for non-string data of variable depth.
    #
    # @param    (see Arachni::Element::Capabilities::Inputtable#inputs=)
    # @return   (see Arachni::Element::Capabilities::Inputtable#inputs=)
    # @raise    (see Arachni::Element::Capabilities::Inputtable#inputs=)
    #
    # @see  Arachni::Element::Capabilities::Inputtable#inputs=
    def inputs=( h )
        h = h.my_stringify_keys

        @inputs = h
        update h
        @inputs.freeze
        self.inputs
    end

    # Overrides {Capabilities::Inputtable#[]} to allow for non-string data
    # of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Name of the input whose value to retrieve.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    #
    # @return   [Object]
    #
    # @see  Arachni::Element::Capabilities::Inputtable#[]
    def []( name )
        key, data = find( name )
        data[key]
    end

    # Overrides {Capabilities::Inputtable#[]=} to allow for non-string data
    # of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Name of the input whose value to set.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    # @param    [Object]    value
    #   Value to set.
    #
    # @return   [Object]
    #   `value`
    #
    # @see  Arachni::Element::Capabilities::Inputtable#[]=
    def []=( name, value )
        @inputs = @inputs.dup
        key, data = find( name )

        fail_if_invalid( [key].flatten.last, value )

        data[key] = value
        @inputs.freeze
        value
    end

    # Overrides {Capabilities::Inputtable#update} to allow for non-string data
    # of variable depth.
    #
    # @param    (see Arachni::Element::Capabilities::Inputtable#update)
    # @return   (see Arachni::Element::Capabilities::Inputtable#update)
    # @raise    (see Arachni::Element::Capabilities::Inputtable#update)
    #
    # @see  Arachni::Element::Capabilities::Inputtable#update
    def update( hash )
        traverse_data hash do |path, value|
            self[path] = value
        end
        self
    end

    private

    def find( path )
        data = @inputs
        path = [path].flatten

        while path.size > 1
            k = path.shift
            k = k.to_s if k.is_a? Symbol

            data = data[k]
        end

        k = path.shift
        k = k.to_s if k.is_a? Symbol

        [k, data]
    end

    def traverse_inputs( &block )
        traverse_data( @inputs, &block )
    end

    def traverse_data( data, path = [], &handler )
        case data
            when Hash
                data.each do |k, v|
                    traverse_data( v, path + [k], &handler )
                end

            when Array
                data.each.with_index do |v, i|
                    traverse_data( v, path + [i], &handler )
                end

            else
                handler.call path, data
        end
    end

end

end
end
end
