=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class ResourceExploration

# Loads a {#resource} and {Browser#trigger_event triggers} the specified
# {#event} on the given {#element element}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class EventTrigger < ResourceExploration

    require_relative 'event_trigger/result'

    # @return   [Symbol]
    #   Event to trigger on the given {#element element}.
    attr_accessor :event

    # @return   [Browser::ElementLocator]
    attr_accessor :element

    # Loads a {#resource} and {Browser#trigger_event triggers} the specified
    # {#event} on the given {#element element}.
    def run
        browser.on_new_page { |page| save_result( page: page ) }

        browser.load resource
        browser.trigger_event( resource, element, event )
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
            "@event=#{@event.inspect} @element=#{@element.inspect}>"
    end

end

end
end
end
end
