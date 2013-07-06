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
# XPath Injection audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/91.html
# @see http://www.owasp.org/index.php/XPATH_Injection
# @see http://www.owasp.org/index.php/Testing_for_XPath_Injection_%28OWASP-DV-010%29
#
class Arachni::Modules::XPathInjection < Arachni::Module::Base

    def self.error_strings
        @error_strings ||= read_file( 'errors.txt' )
    end

    # These will hopefully cause the webapp to output XPath error messages.
    def self.payloads
        @payloads ||= %w('" ]]]]]]]]] <!--)
    end

    def self.options
        @options ||= { format: [Format::APPEND], substring: error_strings }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'XPath Injection',
            description: %q{XPath injection module},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/XPATH_Injection'
            },
            targets:     %w(General PHP Java dotNET libXML2),
            issue:       {
                name:            %q{XPath Injection},
                description:     %q{XPath queries can be injected into the web application.},
                tags:            %w(xpath database error injection regexp),
                cwe:             '91',
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in database queries.',
            }
        }
    end

end
