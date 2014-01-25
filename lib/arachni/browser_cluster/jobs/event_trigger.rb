=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'resource_exploration'

module Arachni
class BrowserCluster
module Jobs

# Loads a {#resource} and {Browser#trigger_event triggers} the specified
# {#event} on the given {#element_index element}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < ResourceExploration

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Result < ResourceExploration::Result
    end

    # @return   [Symbol]
    #   Event to trigger on the given {#element_index element}.
    attr_accessor :event

    # @return   [Integer]
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    attr_accessor :element_index

    # @param    [Hash]  options -- In addition to {ResourceExploration} options:
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

    # Loads a {#resource} and {Browser#trigger_event triggers} the specified
    # {#event} on the given {#element_index element}.
    def run
        browser.on_new_page { |page| save_result( page: page ) }

        browser.load resource
        browser.trigger_event( resource, element_index, event )
    end

end

end
end
end
