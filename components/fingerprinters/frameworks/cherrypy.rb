=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies CherryPy resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class CherryPy < Platform::Fingerprinter

    def run
        return if !server_or_powered_by_include?( 'cherrypy' )

        update_platforms
    end

    def update_platforms
        platforms << :python << :cherrypy
    end

end

end
end
