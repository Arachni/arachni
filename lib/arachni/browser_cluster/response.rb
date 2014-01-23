=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

class BrowserCluster

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Response

    # @return [Page]
    attr_accessor :page

    # @return [Request]
    attr_accessor :request

    # @param    [Hash]  options
    # @option   options [Page]   :page
    #   {#page Page} snapshot that resulted from processing the {#request}.
    # @option   options [Request]   :request
    def initialize( options = {} )
        @page    = options[:page]
        @request = options[:request]
    end

end

end
end
