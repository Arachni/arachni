=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Tomcat web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Tomcat < Platform::Fingerprinter

    def run
        platforms << :tomcat << :jsp if server_or_powered_by_include? 'tomcat'
    end

end

end
end
