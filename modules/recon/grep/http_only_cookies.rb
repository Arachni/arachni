=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
module Modules

#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
class HttpOnlyCookies < Arachni::Module::Base

    def run
        @@_logged ||= Set.new

        [page.cookies].compact.flatten.each {
            |cookie|
            next if cookie.http_only? || @@_logged.include?( cookie.name )
            log_issue(
                :var          => cookie.name,
                :url          => page.url,
                :elem         => cookie.type,
                :method       => page.method,
                :response     => page.body,
                :headers      => {
                    :response   => page.response_headers
                }
            )

            @@_logged << cookie.name
        }
    end

    def self.info
        {
            :name           => 'HttpOnly cookies',
            :description    => %q{Logs cookies that are accessible via JavaScript.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :references     => {
                'HttpOnly - OWASP' => 'https://www.owasp.org/index.php/HttpOnly'
            },
            :issue   => {
                :name        => %q{HttpOnly cookie},
                :description => %q{The logged cookie does not have the HttpOnly
                    flag set which makes it succeptible to maniplation via client-side code.},
                :cwe         => '200',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Set the 'Secure' flag in the cookie.},
                :remedy_code => '',
            }
        }
    end

end
end
end
