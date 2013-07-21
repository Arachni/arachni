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
# HTTP Response Splitting audit module.
#
# It audits links, forms and cookies.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.8
#
# @see http://cwe.mitre.org/data/definitions/20.html
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
# @see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html
#
class Arachni::Modules::ResponseSplitting < Arachni::Module::Base

    def run
        header_name = "X-CRLF-Safe-#{seed}"

        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the attack was successful
        # thus site is vulnerable.
        header = "\r\n#{header_name}: no"

        # try to inject the headers into all vectors
        # and pass a block that will check for a positive result
        audit( header, param_flip: true, follow_location: false ) do |res, element|
            next if res.headers[header_name].to_s.downcase != 'no'
            opts = element.audit_options
            opts[:injected] = uri_encode( opts[:injected] )
            log( opts, res )
        end
    end

    def self.info
        {
            name:        'Response Splitting',
            description: %q{Tries to inject some data into the webapp and figure out
                if any of them end up in the response header.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.8',
            references:  {
                'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                'OWASP'      => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Response Splitting},
                description:     %q{The web application includes user input
     in the response HTTP header.},
                tags:            %w(response splitting injection header),
                cwe:             '20',
                severity:        Severity::MEDIUM,
                cvssv2:          '5.0',
                remedy_guidance: %q{User inputs must be validated and filtered
    before being included as part of the HTTP response headers.},
                remedy_code:     '',
            }

        }
    end

end
