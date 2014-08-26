=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies *nix operating systems whose flavor couldn't be determines.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Unix < Platform::Fingerprinter

    def run
        platforms << :unix if server_or_powered_by_include? 'unix'
    end

end

end
end
