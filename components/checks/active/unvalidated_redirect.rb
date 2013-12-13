=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Unvalidated redirect check.
#
# It audits links, forms and cookies, injects URLs and checks the `Location`
# header field to determine whether the attack was successful.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.6
# @see http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
class Arachni::Checks::UnvalidatedRedirect < Arachni::Check::Base

    def self.payloads
        @payloads ||= [
            'www.arachni-boogie-woogie.com',
            'https://www.arachni-boogie-woogie.com',
            'http://www.arachni-boogie-woogie.com'
        ]
    end

    def run
        audit( self.class.payloads ) do |response, element|
            next if !self.class.payloads.include?( response.headers.location )
            log( { vector: element }, response )
        end
    end

    def self.info
        {
            name:        'Unvalidated redirect',
            description: %q{Injects URLs and checks the Location header field
                to determnine whether the attack was successful.},
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Unvalidated redirect},
                description:     %q{The web application redirects users to unvalidated URLs.},
                references:  {
                    'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards'
                },
                tags:            %w(unvalidated redirect injection header location),
                cwe:             819,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Server side verification should be employed
                    to ensure that the redirect destination is the one intended.}
            }
        }
    end

end
