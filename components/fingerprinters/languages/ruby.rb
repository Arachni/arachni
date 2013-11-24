=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Ruby resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class Ruby < Platform::Fingerprinter

    IDs = %w(mod_rails mod_rack phusion passenger)

    def run
        IDs.each do |id|
            next if !server_or_powered_by_include? id
            return platforms << :ruby
        end
    end

end

end
end
