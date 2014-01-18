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

    # @param    [Javascript]    javascript  Active {Javascript} interface.
    # @param    [String]    object
    #   Name of the JS-side object -- will be prefixed with a generated '_token'.
    def initialize( javascript, object )
        @javascript = javascript
        @stub = Stub.new( javascript, object )
    end

    # @param    [Symbol]    function    Javascript property/function.
    # @param    [Array]    arguments
    def method_missing( function, *arguments )
        @javascript.run "return #{stub.write( function, *arguments )}"
    end

    # @param    [Symbol]    property
    # @return   [Bool]
    #   `true` if `self` of the JS object responds to `property`,
    #   `false` otherwise.
    def respond_to?( property )
        super( property ) || stub.respond_to?( property )
    end

end

end
end
