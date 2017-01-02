=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# HTTP Response Splitting check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2.3
#
# @see http://cwe.mitre.org/data/definitions/20.html
# @see https://www.owasp.org/index.php/HTTP_Response_Splitting
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
        audit(
            header,
            submit: {
                follow_location:   false,
                response_max_size: 0
            }
        ) do |response, element|
            next if response.headers[header_name].to_s.downcase != 'no'

            log(
                vector:   element,
                response: response,
                proof:    response.headers_string[/#{header_name}.*$/i]
            )
        end
    end

    def self.info
        {
            name:        'Response Splitting',
            description: %q{
Injects arbitrary and checks if any of them end up in the response header.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.2.3',

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
                    'OWASP'      => 'https://www.owasp.org/index.php/HTTP_Response_Splitting'
                },
                tags:            %w(response splitting injection header),
                cwe:             20,
                severity:        Severity::HIGH,
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
