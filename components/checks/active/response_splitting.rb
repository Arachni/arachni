=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# HTTP Response Splitting check.
#
# It audits links, forms and cookies.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
# @see http://cwe.mitre.org/data/definitions/20.html
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
# @see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html
class Arachni::Checks::ResponseSplitting < Arachni::Check::Base

    def run
        header_name = "X-CRLF-Safe-#{random_seed}"

        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the attack was successful
        # thus site is vulnerable.
        header = "\r\n#{header_name}: no"

        # try to inject the headers into all vectors
        # and pass a block that will check for a positive result
        audit( header,
               param_flip: true,
               submit: { follow_location: false }
        ) do |response, element|
            next if response.headers[header_name].to_s.downcase != 'no'
            log vector: element, response: response
        end
    end

    def self.info
        {
            name:        'Response Splitting',
            description: %q{Tries to inject some data into the webapp and figure out
                if any of them end up in the response header.},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.8',

            issue:       {
                name:            %q{Response Splitting},
                description:     %q{The web application includes user input
     in the response HTTP header.},
                references:  {
                    'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                    'OWASP'      => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
                },
                tags:            %w(response splitting injection header),
                cwe:             20,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{User inputs must be validated and filtered
    before being included as part of the HTTP response headers.}
            }

        }
    end

end
