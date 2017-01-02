=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
class Job

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
