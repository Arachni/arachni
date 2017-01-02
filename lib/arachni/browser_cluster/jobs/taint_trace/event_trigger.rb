=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class TaintTrace

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class EventTrigger < DOMExploration::EventTrigger

    require_relative 'event_trigger/result'

    def run
        browser.javascript.taint       = forwarder.taint
        browser.javascript.custom_code = forwarder.injector

        browser.on_new_page_with_sink { |page| save_result( page: page ) }

        super
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
            "@event=#{@event.inspect} @element=#{@element.inspect} " +
            "@forwarder=#{@forwarder} time=#{@time} timed_out=#{timed_out?}>"
    end

end

end
end
end
end
