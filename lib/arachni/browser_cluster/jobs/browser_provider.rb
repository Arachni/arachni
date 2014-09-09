=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class BrowserCluster
module Jobs

# Works together with {BrowserCluster#with_browser} to provide the callback
# for this job with the {Browser} assigned to this job.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class BrowserProvider < Job

    def run
        browser.master.callback_for( self ).call browser
    end

    def to_s
        "#<#{self.class}:#{object_id} #{callback_for( self )}>"
    end

end

end
end
end
