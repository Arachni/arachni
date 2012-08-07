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

#
# Unvalidated redirect audit module.
#
# It audits links, forms and cookies, injects URLs and checks
# the Location header field to determine whether the attack was successful.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
# @see http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
#
class Arachni::Modules::UnvalidatedRedirect < Arachni::Module::Base

    def self.urls
        @urls ||= ['www.arachni-boogie-woogie.com',
                   'https://www.arachni-boogie-woogie.com',
                   'http://www.arachni-boogie-woogie.com']
    end

    def run
        self.class.urls.each do |url|
            audit( url ) { |res, opts| log( opts, res ) if self.class.urls.include?( res.location ) }
        end
    end

    def self.info
        {
            name:        'UnvalidatedRedirect',
            description: %q{Injects URLs and checks the Location header field
                to determnine whether the attack was successful.},
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
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
                remedy_guidance: %q{Server side verification should be employed to verifies whether or not the redirected destination is its original intent.}
            }
        }
    end

end
