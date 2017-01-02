=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies PHP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.1
class PHP < Platform::Fingerprinter

    EXTENSION = /php\d*/  # In case it's php5 or something.
    SESSIONID = 'phpsessid'

    def run
        if uri.path =~ /.php\d*\/*/ || extension =~ EXTENSION ||
            parameters.include?( SESSIONID ) ||
            server_or_powered_by_include?( 'php' ) ||
            headers.include?( 'x-php-pid' ) ||
            cookies.include?( SESSIONID )

            platforms << :php
        end
    end

end

end
end
