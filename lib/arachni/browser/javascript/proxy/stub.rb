=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Browser::Javascript::Proxy

# @note Extends `BasicObject` because we don't want any baggage to avoid
#   method clashes with the Javascript-side objects.
#
# Prepares JS calls for the given object based on property type.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Stub < BasicObject

    # @param    [Proxy]    proxy
    #   Parent {Proxy}.
    def initialize( proxy )
        @proxy = proxy
    end

    # @param    [#to_sym] name
    #   Function name.
    # @param    [Array] arguments
    #   Arguments to pass to the JS function.
    #
    # @return   [String]
    #   JS code to call the given function.
    def function( name, *arguments )
        arguments = arguments.map { |arg| arg.to_json }.join( ', ' )

        if name.to_s.end_with?( '=' )
            "#{property( name )}#{arguments if !arguments.empty?}"
        else
            "#{property( name )}(#{arguments if !arguments.empty?})"
        end
    end

    # @param    [#to_sym] name
    #   Function name.
    #
    # @return   [String]
    #   JS code to retrieve the given property.
    def property( name )
        "#{@proxy.js_object}.#{name}"
    end

    # @param    [#to_sym] name
    #   Function/property name.
    # @param    [Array] arguments
    #   Arguments to pass to the JS function.
    #
    # @return   [String]
    #   JS code to call the given function or retrieve the given property.
    #   (Type detection is performed by {Proxy#function?}.)
    def write( name, *arguments )
        @proxy.function?( name ) ?
            function( name, *arguments ) : property( name )
    end
    alias :method_missing :write

    def class
        Stub
    end

    # @return   [String]
    def to_s
        "<#{self.class}##{object_id} #{@proxy.js_object}>"
    end

    # @param    [Symbol]    property
    #
    # @return   [Bool]
    #   `true` if `self` of the JS object responds to `property`,
    #   `false` otherwise.
    def respond_to?( property )
        property = property.to_s
        property = property[0...-1] if property.end_with? '='

        @proxy.javascript.run( "return ('#{property}' in #{@proxy.js_object})" )
    end

end

end
end
