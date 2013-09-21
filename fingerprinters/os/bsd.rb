=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies BSD operating systems.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
