=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Jetty web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Jetty < Platform::Fingerprinter

    def run
        platforms << :jsp << :jetty if server_or_powered_by_include? 'jetty'
    end

end

end
end
