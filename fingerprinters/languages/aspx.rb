=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Platforms::Fingerprinters

#
# Identifies ASPX resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class ASPX < Base

    EXTENSION       = 'aspx'
    SESSION_COOKIE  = 'asp.net_sessionid'
    X_POWERED_BY    = 'asp.net'
    VIEWSTATE       = 'viewstate'
    HEADER_FIELDS   = Set.new( %w(x-aspnet-version x-aspnetmvc-version) )

    def run
        parsed_uri = uri_parse( page.url )

        extension = parsed_uri.resource_extension.to_s.downcase
        return update_platforms if extension == EXTENSION

        # Session ID in URL, like:
        #   http://blah.com/(S(yn5cby55lgzstcen0ng2b4iq))/stuff.aspx
        return update_platforms if parsed_uri.path =~ /\/\(s\([a-z0-9]+\)\)\//i

        page.cookies.each do |cookie|
            return update_platforms if cookie.name.downcase == SESSION_COOKIE
        end

        page.forms.each do |form|
            form.auditable.each do |k, v|
                return update_platforms if k.downcase.include? VIEWSTATE
            end
        end

        page.response_headers.each do |k, v|
            return update_platforms if HEADER_FIELDS.include? k.downcase
            if k.downcase == 'x-powered-by' && v.downcase.start_with?( X_POWERED_BY )
                return update_platforms
            end
        end
    end

    def update_platforms
        platforms << :aspx << :windows
    end

end

end
end
