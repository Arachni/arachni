=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class DOMExploration

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Result < Job::Result

    # @return [Page]
    attr_accessor :page

    def to_s
        "#<#{self.class}:#{object_id} @job=#{@job} @page=#{@page}>"
    end

end

end
end
end
end
