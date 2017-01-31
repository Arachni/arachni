=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Browser

# Lazy-loaded, {Browser} element representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class ElementLocator

    ARACHNI_ID = 'data-arachni-id'

    # @return   [Symbol]
    #   Tag name of the element.
    attr_accessor :tag_name

    # @return   [Hash]
    #   Attributes of the element.
    attr_accessor :attributes

    # @param    [Hash]  options
    #   Data used to set attributes via setters.
    def initialize( options = {} )
        options.each { |k, v| send( "#{k}=", v ) }
        @attributes ||= {}
    end

    # @param    [String, Symbol]    name
    #
    # @return   [Symbol]
    def tag_name=( name )
        @tag_name = name.to_sym
    end

    # @param    [Hash]  attributes
    #   Attributes used to locate the element.
    #
    # @return   [Hash]
    #   Frozen and stringified version of the hash.
    def attributes=( attributes )
        @attributes = (attributes || {}).stringify_recursively_and_freeze
    end

    # @return   [Hash]
    #   Hash with attributes supported by `Watir` when locating elements.
    def locatable_attributes
        attributes.inject({}) do |h, (k, v)|
            string_key = k.to_s
            attribute  = string_key.gsub( '-' ,'_' ).to_sym

            if !self.class.supported_element_attributes_for( tag_name ).include?( attribute ) &&
                !string_key.start_with?( 'data-' )
                next h
            end

            h[attribute] = v.to_s
            h
        end
    end

    # @return   [Selenium::WebDriver::Element]
    #   Locates and returns the element based on {#css}.
    def locate( browser )
        browser.selenium.find_element( :css, css )
    end

    def css
        attrs = {}

        # If there's an ID attribute that's good enough, don't include anything
        # else to avoid risking broken selectors due to dynamic attributes and
        # values.
        if attributes['id']
            attrs['id'] = attributes['id']

        # If we have our own attribute trust it more than the rest,
        # 'class' attributes and others can change dynamically.
        elsif attributes[ARACHNI_ID]
            attrs[ARACHNI_ID] = attributes[ARACHNI_ID]

        # Alternatively, exclude data attributes (except from ours ) to prevent
        # issues and use whatever other attributes are available.
        else
            attrs = attributes.reject do |k, v|
                k.to_s.start_with?( 'data-' )
            end
        end

        "#{tag_name}#{attrs.map { |k, v| "[#{k}=\"#{v.escape_double_quote}\"]"}.join}"
    end

    # @return   [String]
    #   Locator as an HTML opening tag.
    def to_s
        "<#{tag_name}#{' ' if attributes.any?}" <<
            attributes.map { |k, v| "#{k}=\"#{v.escape_double_quote}\"" }.join( ' ' ) << '>'
    end
    alias :inspect :to_s

    def dup
        self.class.new to_h
    end

    # @return   [Hash]
    def to_hash
        {
            tag_name:   tag_name,
            attributes: attributes
        }
    end
    alias :to_h :to_hash

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        to_h.my_stringify_keys
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [ElementLocator]
    def self.from_rpc_data( data )
        new data
    end

    def hash
        to_hash.hash
    end

    def ==( other )
        hash == other.hash
    end

    def self.from_html( html )
        from_node Parser.parse_fragment( html )
    end

    def self.from_node( node )
        attributes = node.attributes.inject({}) do |h, (k, v)|
            h[k.to_s] = v.to_s
            h
        end

        new tag_name: node.name, attributes: attributes
    end

    # @param    [String]  tag_name
    #   Opening HTML tag of the element.
    # @return   [Set<Symbol>]
    #   List of attributes supported by Watir.
    def self.supported_element_attributes_for( tag_name )
        @supported_element_attributes_for ||= {}

        tag_name = tag_name.to_sym

        if (klass = Watir.tag_to_class[tag_name])
            @supported_element_attributes_for[tag_name] ||=
                Set.new( klass.attribute_list )
        else
            @supported_element_attributes_for[tag_name] ||= Set.new
        end
    end

end

end
end
