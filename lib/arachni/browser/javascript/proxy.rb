=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
    end

    # @param    [#to_sym] name
    #   Function name to check.
    #
    # @return   [Bool]
    #   `true` if the `name` property of the current object points to a function,
    #   `false` otherwise.
    def function?( name )
        self.class.function?( @javascript, js_object, name )
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

    def self.function?( env, object, name )
        mutex.synchronize do
            @isFunction ||= {}
            key = "#{object}.#{name}".hash

            return @isFunction[key] if @isFunction.include?( key )

            if name.to_s.end_with? '='
                name = name.to_s
                return @isFunction[key] = env.run(
                    "return ('#{name[0...-1]}' in #{object})"
                )
            end

            @isFunction[key] = env.run(
                "return Object.prototype.toString.call( #{object}." <<
                    "#{name} ) == '[object Function]'"
            )
        end
    end
    def self.mutex
        @mutex ||= ::Mutex.new
    end
    mutex

end

end
end
