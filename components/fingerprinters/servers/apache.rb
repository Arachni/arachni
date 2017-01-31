=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Apache web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Apache < Platform::Fingerprinter

    def run
        if server_or_powered_by_include?( 'apache' ) &&
            !server_or_powered_by_include?( 'coyote' )

            platforms << :apache
        end
    end

end

end
end
