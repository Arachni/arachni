=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies BSD operating systems.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class BSD < Platform::Fingerprinter

    def run
        platforms << :bsd if server_or_powered_by_include? 'bsd'
    end

end

end
end
