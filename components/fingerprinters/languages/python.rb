=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

# Identifies Python resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.2
class Python < Platform::Fingerprinter

    IDS       = %w(python zope zserver wsgi plone)
    EXTENSION = 'py'

    def run
        return update_platforms if extension == EXTENSION

        IDS.each do |id|
            return update_platforms if server_or_powered_by_include?( id )
        end

        if cookies.include?( '_ZopeId' )
            update_platforms
        end
    end

    def update_platforms
        platforms << :python
    end

end

end
end
