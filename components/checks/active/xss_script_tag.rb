=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# XSS in HTML script tag.
# It injects strings and checks if they appear inside HTML 'script' tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XSSScriptTag < Arachni::Check::Base

    REMARK = 'Arachni cannot inspect the JavaScript runtime in order to' +
        'determine the real effects of the injected seed, a human needs to inspect' +
        'this issue to determine its validity.'

    def self.strings
        @strings ||= [ "'\"()arachni_xss_in_script_tag_#{seed}" ]
    end

    def self.opts
        @opts ||= { format: [ Format::APPEND ] }
    end

    def run
        audit( self.class.strings, self.class.opts ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # if we have no body or it doesn't contain the injected string under any
        # context there's no point in parsing the HTML to verify the vulnerability
        return if element.seed.to_s.empty? || !response.body ||
            !response.body.include?( element.seed )

        Nokogiri::HTML( response.body ).css( 'script' ).each do |script|
            next if !script.to_s.include?( element.seed )

            log({
                     vector:    element,
                     trusted:   false,
                     proof:     script.to_s,
                     remarks:   { check: [ REMARK ] }
                 },
                 response
            )

            break
        end
    end

    def self.info
        {
            name:        'XSS in HTML \'script\' tag',
            description: %q{Injects strings and checks if they appear inside HTML 'script' tags.},
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.4',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Scripting in HTML \'script\' tag},
                description:     %q{Unvalidated user input is being embedded inside a <script> element.
    This makes Cross-Site Scripting attacks much easier to mount since user input lands inside
    a trusted script.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss script tag regexp dom attribute injection),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in executable code or not be included at all.'
            }
        }
    end

end
