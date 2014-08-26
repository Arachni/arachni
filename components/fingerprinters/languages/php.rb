=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies PHP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class PHP < Platform::Fingerprinter

    EXTENSION = /php\d*/  # In case it's php5 or something.
    SESSIONID = 'phpsessid'

    def run
        if uri.path =~ /.php\d*\/*/ || extension =~ EXTENSION ||
            parameters.include?( SESSIONID ) || cookies.include?( SESSIONID ) ||
            server_or_powered_by_include?( 'php' )
            platforms << :php
        end
    end

end

end
end
