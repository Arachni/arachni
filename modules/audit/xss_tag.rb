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
# XSS in HTML tag.
# It injects a string and checks if it appears inside any HTML tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class Arachni::Modules::XSSHTMLTag < Arachni::Module::Base

    TAG_NAME = 'arachni_xss_in_tag'

    def self.strings
        @strings ||= [ " #{TAG_NAME}=" + seed, "\" #{TAG_NAME}=\"" + seed,
                       "' #{TAG_NAME}='" + seed ]
    end

    def run
        self.class.strings.each do |str|
            audit( str, format: [ Format::APPEND ] ) do |res, element|
                check_and_log( res, element.audit_options )
            end
        end
    end

    def check_and_log( res, opts )
        # if we have no body or it doesn't contain the TAG_NAME under any
        # context there's no point in parsing the HTML to verify the vulnerability
        return if !res.body || !res.body.include?( TAG_NAME )

        # see if we managed to inject a working HTML attribute to any
        # elements
        Nokogiri::HTML( res.body ).xpath( "//*[@#{TAG_NAME}]" ).each do |element|
            next if element[TAG_NAME] != seed

            opts[:match] = (payload = find_included_payload( res.body )) ? payload : element.to_s
            log( opts, res )
        end
    end

    def find_included_payload( body )
        self.class.strings.each do |payload|
            return payload if body.include?( payload )
        end
        nil
    end

    def self.info
        {
            name:        'XSS in HTML tag',
            description: %q{Cross-Site Scripting in HTML tag.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.5',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in HTML tag},
                description:     %q{Unvalidated user input is being embedded in a HTML element.
    This can lead to a Cross-Site Scripting vulnerability or a form of HTML manipulation.},
                tags:            %w(xss script tag regexp dom attribute injection),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.',
            }

        }
    end

end
