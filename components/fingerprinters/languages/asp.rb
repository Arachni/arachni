=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies ASP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class ASP < Platform::Fingerprinter

    EXTENSION = 'asp'
    SESSIONID = 'aspsessionid'

    def run
        return if extension != EXTENSION && !parameters.include?( SESSIONID ) &&
            !cookies.include?( SESSIONID ) && !server_or_powered_by_include?( 'asp' )

        platforms << :asp << :windows
    end

end

end
end
