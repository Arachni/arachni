=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Tomcat web servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Tomcat < Platform::Fingerprinter

    IDS = %w(coyote tomcat)

    def run
        IDS.each do |id|
            next if !server_or_powered_by_include? id

            return update_platforms
        end
    end

    def update_platforms
        platforms << :java << :tomcat
    end

end

end
end
