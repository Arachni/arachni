=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs

# Loads a {#resource} and {Browser#trigger_events explores} its DOM.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ResourceExploration < Job

    # @param    [Hash]  options
    # @option   options [Page]   :page
    #   {#page Page} snapshot that resulted from running the {#job}.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Result < Job::Result
        # @return [Page]
        attr_accessor :page
    end

    # @return [Page, String, HTTP::Response]
    #   Resource to explore, if given a `String` it will be treated it as a URL
    #   and will be loaded.
    attr_accessor :resource

    # @param    [Hash]  options
    # @option   options [Page, String, HTTP::Response]   :resource
    #   Resource to explore, if given a `String` it will be treated it as a URL.
    def initialize( options = {} )
        super options
        @resource = options[:resource]
    end

    # Loads a {#resource} and {Browser#trigger_events explores} its DOM.
    def run
        browser.on_new_page { |page| save_result( page: page ) }

        browser.load resource
        browser.trigger_events
    end

end

end
end
end
