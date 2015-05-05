=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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

    # @return   [Watir::HTMLElement]
    #   Locates and returns the element based on {#tag_name} and {#attributes}.
    def locate( browser )
        browser.watir.element( css: css )
    end

    def css
        "#{tag_name}#{attributes.map { |k, v| "[#{k}=#{v.inspect}]"}.join}"
    end

    # @return   [String]
    #   Locator as an HTML opening tag.
    def to_s
        "<#{tag_name}#{' ' if attributes.any?}" <<
            attributes.map { |k, v| "#{k}=#{v.inspect}" }.join( ' ' ) << '>'
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
        from_node Nokogiri::HTML.fragment( html ).children.first
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
