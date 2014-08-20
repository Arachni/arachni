=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
class BrowserCluster
module Jobs
class ResourceExploration

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Result < Job::Result
    # @return [Page]
    attr_accessor :page
end

end
end
end
end
