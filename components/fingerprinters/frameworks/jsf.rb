=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies JSF resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
class JSF < Platform::Fingerprinter

    def run
        if server_or_powered_by_include?( 'jsf' ) ||
            parameters.include?( 'javax.faces.token')

            platforms << :java << :jsf
        end
    end

end

end
end
