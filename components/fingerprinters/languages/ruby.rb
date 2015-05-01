=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Ruby resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
