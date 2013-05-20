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
# Identifies PHP resources.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
class PHP < Base

    EXTENSION = /php\d*/  # In case it's php5 or something.
    SESSIONID = 'phpsessid'

    def run
        extension = uri_parse( page.url ).resource_extension.to_s.downcase
        return update_platforms if extension =~ EXTENSION

        page.query_vars.keys.each do |param|
            return update_platforms if param.downcase == SESSIONID
        end

        page.cookies.each do |cookie|
            return update_platforms if cookie.name.downcase == SESSIONID
        end

        page.headers.each do |header|
            if header.name.downcase == 'x-powered-by' &&
                header.value.downcase.start_with?( 'php/' )
                return update_platforms
            end
        end
    end

    def update_platforms
        platforms << :php
    end

end

end
end
