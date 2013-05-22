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

#
# Unvalidated redirect audit module.
#
# It audits links, forms and cookies, injects URLs and checks the `Location`
# header field to determine whether the attack was successful.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
#
class Arachni::Modules::UnvalidatedRedirect < Arachni::Module::Base

    def self.payloads
        @payloads ||= [
            'www.arachni-boogie-woogie.com',
            'https://www.arachni-boogie-woogie.com',
            'http://www.arachni-boogie-woogie.com'
        ]
    end

    def run
        audit( self.class.payloads ) do |res, opts|
            next if !self.class.payloads.include?( res.location )
            log( opts, res )
        end
    end

    def self.info
        {
            name:        'Unvalidated redirect',
            description: %q{Injects URLs and checks the Location header field
                to determnine whether the attack was successful.},
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            references:  {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Unvalidated redirect},
                description:     %q{The web application redirects users to unvalidated URLs.},
                tags: %w(unvalidated redirect injection header location),
                cwe:             '819',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Server side verification should be employed
                    to ensure that the redirect destination is the one intended.}
            }
        }
    end

end
