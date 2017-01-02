=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Solaris operating systems.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Solaris < Platform::Fingerprinter

    IDs = %w(solaris sunos)

    def run
        IDs.each do |id|
            next if !server_or_powered_by_include? id
            return platforms << :solaris
        end
    end

end

end
end
