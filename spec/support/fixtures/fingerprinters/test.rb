=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Apache web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Test < Platform::Fingerprinter

    def run
        platforms << :unix << :apache
    end

end

end
end
