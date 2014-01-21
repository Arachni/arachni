=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser::Javascript

# @note Extends {BasicObject} because we don't want any baggage to avoid
#   method-name clashes with the Javascript-side objects.
#
# Provides a proxy to a Javascript object.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Proxy < BasicObject
    require_relative 'proxy/stub'

    # @return   [Stub]  Stub interface for JS code.
    attr_reader :stub

    # @return   [Javascript]    javascript  Active {Javascript} interface.
    attr_reader :javascript

    # @param    [Javascript]    javascript  Active {Javascript} interface.
    # @param    [String]    object
    #   Name of the JS-side object -- will be prefixed with a generated '_token'.
    def initialize( javascript, object )
        @javascript = javascript
        @object     = object
        @stub       = Stub.new( self )
        @isFunction = {}
    end

    # @param    [#to_sym] name  Function name to check.
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

    # @param    [Symbol]    function    Javascript property/function.
    # @param    [Array]    arguments
    def call( function, *arguments )
        @javascript.run "return #{stub.write( function, *arguments )}"
    end
    alias :method_missing :call

    # @param    [Symbol]    property
    # @return   [Bool]
    #   `true` if `self` of the JS object responds to `property`,
    #   `false` otherwise.
    def respond_to?( property )
        stub.respond_to?( property )
    end

end

end
end
