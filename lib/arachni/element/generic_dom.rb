=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents generic DOM elements, basically anything that can be part of a
# {Page::DOM::Transition}, and is used just for wrapping them in something
# that presents an interface compatible with the other, more traditional,
# elements when logging {Issue issues}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class GenericDOM < Base
    include Capabilities::WithAuditor

    # @return   [Page::DOM::Transition]
    attr_reader :transition

    # @param    [Hash]    options
    # @option   options [String]    :url
    # @option   options [Page::DOM::Transition]    :transition
    def initialize( options = {} )
        super

        @transition = options[:transition]
        fail 'Missing element locator.' if !@transition

        @initialization_options = options
    end

    # @return   [Symbol]    DOM event.
    # @see Page::DOM::Transition#event
    def event
        transition.event
    end
    alias :method :event

    # @return   [Browser::Element::Locator]
    #   Locator for the logged element.
    # @see Page::DOM::Transition#element
    def element
        transition.element
    end

    # @return   [Hash]
    #   Element attributes.
    # @see Browser::Element::Locator#attributes
    def attributes
        element.attributes
    end

    # @return   [String, nil]
    #   Name or ID from the {#attributes} if any are defined.
    def name
        attributes['name'] || attributes['id']
    end
    alias :affected_input_name :name

    # @return   [String, nil]
    #   Element value (in case of an input) from the {#transition}
    #   {Page::DOM::Transition#options}.
    def value
        transition.options[:value]
    end
    alias :affected_input_value value

    # @return   [Hash]
    def to_h
        super.merge( transition: transition.to_h.tap { |h| h[:element] = h[:element].to_h } )
    end

    # @return   [Symbol]
    #   Element tag name.
    # @see Browser::Element::Locator#tag_name
    def type
        element.tag_name
    end

    def self.from_rpc_data( data )
        instance = allocate
        data.each do |name, value|
            value = case name
                        when 'transition'
                            Arachni::Page::DOM::Transition.from_rpc_data( value )

                        when 'initialization_options'
                            value = value.is_a?( Hash ) ? value.symbolize_keys(false) : value
                            value[:transition] =
                                Arachni::Page::DOM::Transition.from_rpc_data( value[:transition] )
                            value

                        else
                            value
                    end

            instance.instance_variable_set( "@#{name}", value )
        end
        instance
    end

end
end
