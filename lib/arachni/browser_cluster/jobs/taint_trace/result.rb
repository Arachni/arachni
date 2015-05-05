=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs
class TaintTrace

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Result < Job::Result
    # @return [Page]
    attr_accessor :page
end

end
end
end
end
