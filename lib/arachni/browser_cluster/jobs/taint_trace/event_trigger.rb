=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class TaintTrace

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
