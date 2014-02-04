=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

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
class Arachni::Checks::XSSHTMLTag < Arachni::Check::Base

    TAG_NAME = 'arachni_xss_in_tag'

    def self.strings
        @strings ||= [ " #{TAG_NAME}=" + seed, "\" #{TAG_NAME}=\"" + seed,
                       "' #{TAG_NAME}='" + seed ]
    end

    def run
        audit( self.class.strings, format: [ Format::APPEND ] ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # if we have no body or it doesn't contain the TAG_NAME under any
        # context there's no point in parsing the HTML to verify the vulnerability
        return if !response.body || !response.body.include?( TAG_NAME )

        # see if we managed to inject a working HTML attribute to any
        # elements
        Nokogiri::HTML( response.body ).xpath( "//*[@#{TAG_NAME}]" ).each do |node|
            next if node[TAG_NAME] != seed

            proof = (payload = find_included_payload( response.body )) ? payload : node.to_s
            log vector: element, proof: proof, response: response
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
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.5',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in HTML tag},
                description:     %q{Unvalidated user input is being embedded in a HTML element.
    This can lead to a Cross-Site Scripting vulnerability or a form of HTML manipulation.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },

                tags:            %w(xss script tag regexp dom attribute injection),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.'
            }

        }
    end

end
