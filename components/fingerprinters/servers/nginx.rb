=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Nginx web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Nginx < Platform::Fingerprinter

    def run
        platforms << :nginx if server_or_powered_by_include? 'nginx'
    end

end

end
end
