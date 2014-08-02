=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Platform::Fingerprinters

#
# Identifies ASPX resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
