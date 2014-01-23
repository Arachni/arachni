=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Request

    # @return [Page, String, HTTP::Response]
    #   Resource to process, if given a `String` it will be treated it as a URL.
    attr_accessor :resource

    # @return   [Symbol]
    #   Event to trigger on the given {#element_index element}.
    attr_accessor :event

    # @return   [Integer]
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    attr_accessor :element_index

    class <<self
        def increment_id
            @id ||= 0
            @id += 1
        end
    end

    # @param    [Hash]  options
    # @option   options [Page, String, HTTP::Response]   :resource
    #   Resource to process, if given a `String` it will be treated it as a URL.
    # @option   options [Symbol]   :event
    #   Event to trigger on the given {#element_index element}.
    # @option   options [Integer]   :element_index
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    def initialize( options = {} )
        @id            = options.delete(:id) || self.class.increment_id
        @resource      = options[:resource]
        @event         = options[:event]
        @element_index = options[:element_index]
    end

    # @param    [Hash]  options See {#initialize}.
    # @return   [Request]
    #   Re-used request (mainly its {#id} and thus its callback as well),
    #   configured with the given `options`.
    def forward( options = {} )
        self.class.new options.merge( id: @id )
    end

    # @return   [Bool]
    #   `true` if this request is for triggering a single {#event} on the given
    #   {#element_index element}, `false` otherwise.
    def single_event?
        @event && @element_index
    end

    # @return   [Integer]
    #   ID, used by the {BrowserCluster}, to tie requests to callbacks.
    def id
        @id
    end

end

end
end
