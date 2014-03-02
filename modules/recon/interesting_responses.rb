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

require 'digest/md5'

#
# Logs all non 200 (OK) and non 404 server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
class Arachni::Modules::InterestingResponses < Arachni::Module::Base

    IGNORE_CODES = [ 200, 404 ].to_set

    def self.ran?
        @ran ||= false
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        # tell the HTTP interface to call this block every-time a request completes
        http.add_on_complete { |res| check_and_log( res ) }
    end

    def clean_up
        self.class.ran
    end

    def check_and_log( res )
        return if IGNORE_CODES.include?( res.code ) || res.body.to_s.empty? ||
            issue_limit_reached?

        digest = Digest::MD5.hexdigest( res.body )
        path   = uri_parse( res.effective_url ).path

        return if audited?( path ) || audited?( digest )

        audited( path )
        audited( digest )

        log( { id: "Code: #{res.code}", element: Element::SERVER }, res )
        print_ok "Found an interesting response -- Code: #{res.code}."
    end

    def self.info
        {
            name:        'Interesting responses',
            description: %q{Logs all non 200 (OK) server responses.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            targets:     %w(Generic),
            references:  {
                'w3.org' => 'http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html'
            },
            issue:       {
                name:        %q{Interesting response},
                description: %q{During scanning Arachni trains itself by 
                    learning from the HTTP responses it receives during the 
                    audit process. It is able to perform meta-analysis using a 
                    number of factors in order to correctly assess the 
                    trustworthiness of results and intelligently identify false-
                    positives. Because of this, Arachni is also able to identify 
                when a web application responds in an unpredictable manner. 
                    Unpredictable meaning the server responded with a status 
                    code (eg, 500) when Arachni was expecting another (eg. 200). 
                    Arachni has flagged a non 200 response not as a 
                    vulnerability, but as a prompt for the penetration tester to 
                    conduct further manual testing on the identified page, as 
                    its unpredictable response may lead to identifying 
                    additional vulnerabilities in the web application or server 
                    deployment. Note: 404 status codes are ignored.},
                tags:        %w(interesting response server),
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{Conduct further manual testing to ensure 
                    that the web application and/or server are responding as 
                    expected and that potential application and/or sever 
                    misconfigurations cannot be abused.}
            },
            max_issues: 25
        }
    end

    def self.acceptable
        [ 102, 200, 201, 202, 203, 206, 207, 208, 226, 300, 301, 302,
          303, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409,
          410, 411, 412, 413, 414, 415, 416, 417, 418, 420, 422, 423, 424, 425, 426, 428,
          429, 431, 444, 449, 450, 451, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508,
          509, 510, 511, 598, 599
        ]
    end

end
