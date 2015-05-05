=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs

# Loads a {#resource} and {Browser#trigger_events explores} its DOM.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class ResourceExploration < Job

    require_relative 'resource_exploration/result'
    require_relative 'resource_exploration/event_trigger'

    # @return [Page, String, HTTP::Response]
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    attr_accessor :resource

    def initialize( options )
        self.resource = options.delete(:resource)
        super options
    end

    # Loads a {#resource} and {Browser#trigger_events explores} its DOM.
    def run
        browser.on_new_page { |page| save_result( page: page ) }

        browser.load resource
        browser.trigger_events
    end

    def resource=( resource )
        # Get a copy of the page with the caches cleared, this way when the
        # modules (or anything else) lazy-load elements and populate the caches
        # there won't be any lingering references to them from the more time
        # consuming browser analysis.
        resource = resource.dup if resource.is_a? Page
        @resource = resource
    end

    def dup
        super.tap { |j| j.resource = resource }
    end

    def clean_copy
        super.tap { |j| j.resource = nil }
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource}>"
    end
    alias :inspect :to_s

end

end
end
end
