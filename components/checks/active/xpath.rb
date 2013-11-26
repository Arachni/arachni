=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# XPath Injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/91.html
# @see http://www.owasp.org/index.php/XPATH_Injection
# @see http://www.owasp.org/index.php/Testing_for_XPath_Injection_%28OWASP-DV-010%29
#
class Arachni::Checks::XPathInjection < Arachni::Check::Base

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
            description: %q{XPath injection check},
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
