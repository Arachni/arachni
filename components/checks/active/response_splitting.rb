=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# HTTP Response Splitting check.
#
# It audits links, forms and cookies.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
            description: %q{
Injects arbitrary and checks if any of them end up in the response header.
},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.8',

            issue:       {
                name:            %q{Response Splitting},
                description:     %q{
HTTP response splitting occurs when untrusted data is inserted into the response
headers without any sanitisation.

If successful, this allows cyber-criminals to essentially split the HTTP response
in two.

This is abused by cyber-criminals injecting CR (Carriage Return -- `/r`)
and LF (Line Feed -- `\n`) characters which will then form the split. If the CR
or LF characters are not processed by the server then it cannot be exploited.

Along with these characters, cyber-criminals can then construct their own
arbitrary response headers and body which would then form the second response.
The second response is entirely under their control, allowing for a number of
other attacks.
},
                references:  {
                    'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                    'OWASP'      => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
                },
                tags:            %w(response splitting injection header),
                cwe:             20,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form the contents of the
response header.

Where any untrusted source is required to be used in the response headers, it is
important to ensure that any hazardous characters (`/r`, `/n` and potentially
others) are sanitised prior to being used.

This is especially important when setting cookie values, redirecting, etc..
},
            }
        }
    end

end
