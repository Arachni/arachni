=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies JSP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class JSP < Platform::Fingerprinter

    EXTENSION = 'jsp'
    SESSIONID = 'jsessionid'

    def run
        if extension == EXTENSION || parameters.include?( SESSIONID ) ||
            cookies.include?( SESSIONID ) ||
            server_or_powered_by_include?( 'servlet' ) ||
            server_or_powered_by_include?( 'jsp' )
            platforms << :jsp
        end
    end

end

end
end
