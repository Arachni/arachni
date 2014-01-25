=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
class Job

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Result

    # @return [Job]
    attr_accessor :job

    # @param    [Hash]  options
    # @option   options [Job]   :job
    def initialize( options = {} )
        options.each { |k, v| send( "#{k}=", v ) }
    end

end

end
end
end
