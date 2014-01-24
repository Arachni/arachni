=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'page_analysis'

module Arachni
class BrowserCluster
module Jobs

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < PageAnalysis

    # @return   [Symbol]
    #   Event to trigger on the given {#element_index element}.
    attr_accessor :event

    # @return   [Integer]
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    attr_accessor :element_index

    # @param    [Hash]  options -- In addition to {PageAnalysis} options:
    # @option   options [Symbol]   :event
    #   Event to trigger on the given {#element_index element}.
    # @option   options [Integer]   :element_index
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    def initialize( options = {} )
        super options

        @event         = options[:event]
        @element_index = options[:element_index]
    end

    def run( browser )
        browser.load resource
        browser.trigger_event( resource, element_index, event )
    end

end

end
end
end
