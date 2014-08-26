=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
class Browser
class Javascript

# Provides access to the `DOMMonitor` JS interface.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOMMonitor < Proxy

    # @param    [Javascript]    javascript
    #   Active {Javascript} interface.
    def initialize( javascript )
        super javascript, 'DOMMonitor'
    end

    def class
        DOMMonitor
    end

end
end
end
end
