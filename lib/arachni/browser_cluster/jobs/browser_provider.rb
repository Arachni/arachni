=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class BrowserCluster
module Jobs

# Works together with {BrowserCluster#with_browser} to provide the callback
# for this job with the {Browser} assigned to this job.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class BrowserProvider < Job

    def run
        browser.master.callback_for( self ).call browser
    end

end

end
end
end
