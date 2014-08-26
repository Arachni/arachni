=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

# Identifies JSP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.1
class JSP < Platform::Fingerprinter

    EXTENSION = 'jsp'
    SESSIONID = 'jsessionid'

    def run
        if extension == EXTENSION || parameters.include?( SESSIONID ) ||
            cookies.include?( SESSIONID ) ||
            server_or_powered_by_include?( 'servlet' ) ||
            server_or_powered_by_include?( 'jsp' )
            platforms << :jsp << :tomcat
        end
    end

end

end
end
