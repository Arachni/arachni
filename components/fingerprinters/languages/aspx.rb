=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies ASPX resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1
#
class ASPX < Platform::Fingerprinter

    EXTENSION       = 'aspx'
    SESSION_COOKIE  = 'asp.net_sessionid'
    X_POWERED_BY    = 'asp.net'
    VIEWSTATE       = 'viewstate'
    HEADER_FIELDS   = %w(x-aspnet-version x-aspnetmvc-version)

    def run
        if extension == EXTENSION ||
            # Session ID in URL, like:
            #   http://blah.com/(S(yn5cby55lgzstcen0ng2b4iq))/stuff.aspx
            uri.path =~ /\/\(s\([a-z0-9]+\)\)\//i ||
            cookies.include?( SESSION_COOKIE )
            return update_platforms
        end

        page.forms.each do |form|
            form.inputs.each do |k, v|
                return update_platforms if k.downcase.include? VIEWSTATE
            end
        end

        if server_or_powered_by_include?( X_POWERED_BY ) ||
            (headers.keys & HEADER_FIELDS).any?
            update_platforms
        end
    end

    def update_platforms
        platforms << :asp << :aspx << :windows
    end

end

end
end
