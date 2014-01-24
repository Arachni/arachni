=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PageAnalysis < Job

    # @return [Page, String, HTTP::Response]
    #   Resource to process, if given a `String` it will be treated it as a URL.
    attr_accessor :resource

    # @param    [Hash]  options
    # @option   options [Page, String, HTTP::Response]   :resource
    #   Resource to process, if given a `String` it will be treated it as a URL.
    def initialize( options = {} )
        super options
        @resource = options[:resource]
    end

    def run( browser )
        browser.load resource
        browser.trigger_events
    end

end

end
end
end
