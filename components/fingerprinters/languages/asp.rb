=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies ASP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
