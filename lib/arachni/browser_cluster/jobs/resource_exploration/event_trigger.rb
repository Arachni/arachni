=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs
class ResourceExploration

# Loads a {#resource} and {Browser#trigger_event triggers} the specified
# {#event} on the given {#element_index element}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < ResourceExploration

    require_relative 'event_trigger/result'

    # @return   [Symbol]
    #   Event to trigger on the given {#element_index element}.
    attr_accessor :event

    # @return   [Integer]
    #   Index of the element in the given {#resource} upon which to trigger
    #   the given {#event}.
    attr_accessor :element_index

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
end
