=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs
class TaintTrace

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class EventTrigger < ResourceExploration::EventTrigger

    require_relative 'event_trigger/result'

    def run
        browser.javascript.taint       = forwarder.taint
        browser.javascript.custom_code = forwarder.injector

        browser.on_new_page_with_sink { |page| save_result( page: page ) }

        super
    end

end

end
end
end
end
