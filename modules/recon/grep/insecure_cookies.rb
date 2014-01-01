=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Modules::InsecureCookies < Arachni::Module::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.secure? || audited?( cookie.name )

            log( var: cookie.name, element: cookie.type, )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Insecure cookies',
            description: %q{Logs cookies that are served over an unencrypted channel.},
            elements:    [ Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            references:  {
                'SecureFlag - OWASP' => 'https://www.owasp.org/index.php/SecureFlag'
            },
            issue:       {
                name:            %q{Insecure cookie},
                description:     %q{The logged cookie is allowed to be served over
    an unencrypted channel which makes it susceptible to sniffing.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Set the 'Secure' flag in the cookie.},
            }
        }
    end

end
