=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies Linux operating systems.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class Linux < Platform::Fingerprinter

    IDs = %w(linux ubuntu gentoo debian dotdeb centos redhat sarge etch lenny
                squeeze wheezy jessie) | ['red hat', 'scientific linux']

    def run
        IDs.each do |id|
            next if !server_or_powered_by_include? id
            return platforms << :linux
        end
    end

end

end
end
