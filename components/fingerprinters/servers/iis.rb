=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies IIS web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class IIS < Platform::Fingerprinter

    def run
        platforms << :windows << :iis if server_or_powered_by_include? 'iis'
    end

end

end
end
