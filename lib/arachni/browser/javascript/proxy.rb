=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Browser::Javascript

# @note Extends `BasicObject` because we don't want any baggage to avoid
#   method-name clashes with the Javascript-side objects.
#
# Provides a proxy to a Javascript object.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Proxy < BasicObject
    require_relative 'proxy/stub'

    # @return   [Stub]
    #   Stub interface for JS code.
    attr_reader :stub

    # @return   [Javascript]
    #   Active {Javascript} interface.
    attr_reader :javascript

    # @param    [Javascript]    javascript
    #   Active {Javascript} interface.
    # @param    [String]    object
    #   Name of the JS-side object -- will be prefixed with a generated '_token'.
    def initialize( javascript, object )
        @javascript = javascript
        @object     = object
        @stub       = Stub.new( self )
        @isFunction = {}
    end

    # @param    [#to_sym] name
    #   Function name to check.
    #
    # @return   [Bool]
    #   `true` if the `name` property of the current object points to a function,
    #   `false` otherwise.
    def function?( name )
        return @isFunction[name.to_sym] if @isFunction.include?( name.to_sym )

        if name.to_s.end_with? '='
            name = name.to_s
            return @isFunction[name.to_sym] = @javascript.run(
                "return ('#{name[0...-1]}' in #{js_object})"
            )
        end

        @isFunction[name.to_sym] =
            @javascript.run(
                "return Object.prototype.toString.call( #{js_object}." <<
                    "#{name} ) == '[object Function]'"
            )
    end

    # @return   [String]
    #   Active JS-side object name -- prefixed with the relevant `_token`.
    def js_object
        "_#{@javascript.token}#{@object}"
    end

    # @param    [Symbol]    function
    #   Javascript property/function.
    # @param    [Array]    arguments
    def call( function, *arguments )
        @javascript.run_without_elements "return #{stub.write( function, *arguments )}"
    end
    alias :method_missing :call

    # @param    [Symbol]    property
    #
    # @return   [Bool]
    #   `true` if `self` of the JS object responds to `property`,
    #   `false` otherwise.
    def respond_to?( property )
        stub.respond_to?( property )
    end

    def class
        Proxy
    end
end

end
end
