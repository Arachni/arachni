=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class DOMExploration

# Loads a {#resource} and {Browser#trigger_event triggers} the specified
# {#event} on the given {#element element}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class EventTrigger < DOMExploration

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

        # We're disabling page restoration for the trigger as this is an one-time
        # job situation, the browser's state is going to be discarded at the end.
        browser.trigger_event( resource, element, event, false )
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
            "@event=#{@event.inspect} @element=#{@element.inspect} " <<
            "time=#{@time} timed_out=#{timed_out?}>"
    end

end

end
end
end
end
