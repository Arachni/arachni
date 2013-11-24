=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Python resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
