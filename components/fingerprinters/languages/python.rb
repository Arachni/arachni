=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Python resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Python < Platform::Fingerprinter

    EXTENSION = 'py'

    def run
        if extension == EXTENSION || powered_by.include?( 'python' )
            platforms << :python
        end
    end

end

end
end
