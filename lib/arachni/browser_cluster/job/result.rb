=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
class Job

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Result

    # @return [Page]
    attr_accessor :page

    # @return [Job]
    attr_accessor :job

    # @param    [Hash]  options
    # @option   options [Page]   :page
    #   {#page Page} snapshot that resulted from running the {#job}.
    # @option   options [Job]   :job
    def initialize( options = {} )
        @page = options[:page]
        @job  = options[:job]
    end

end

end
end
end
