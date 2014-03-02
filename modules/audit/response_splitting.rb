=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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
        audit( header, param_flip: true, follow_location: false ) do |res, opts|
            next if res.headers_hash[header_name].to_s.downcase != 'no'
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
                'OWASP'      => 'http://www.owasp.org/index.php/HTTP_Response_Splitting',
                'WASC'       => 'http://projects.webappsec.org/w/page/13246931/HTTP%20Response%20Splitting'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Response Splitting},
                description:     %q{HTTP response splitting occurs when 
                    untrusted data (usually a client's request) is inserted into 
                    the response headers without any sanitisation or validation. 
                    If vulnerable, this allows a cyber-criminal to essentially 
                    split the HTTP response into two. This is abused by the 
                    cyber-criminal injecting both CR (aka, carriage return, %0d, 
                    or /r) characters and LF (aka, line feed, %0a, or \n) which 
                    will then form the split. If the CR or LF characters are not 
                    processed by the server then it cannot be exploited. Along 
                    with these characters, the cyber-criminal can then construct 
                    their own arbitrary response headers and body which would 
                    then form the second response. The second response is 
                    entirely under their control, and then permits a number of 
                    other attacks.},
                tags:            %w(response splitting injection header),
                cwe:             '20',
                severity:        Severity::MEDIUM,
                cvssv2:          '5.0',
                remedy_guidance: %q{It is recommended that untrusted or 
                    invalidated data is never used to form the contents of the 
                    response header. Where any untrusted source is required to 
                    be used in the response headers, it is important to ensure 
                    that any hazardous characters (%0d, %0a, /r, /n, and 
                    potentially others) are prior to being used. This is 
                    especially important when setting cookie values, redirecting, 
                    or when virtual hosting.},
                remedy_code:     '',
            }

        }
    end

end
