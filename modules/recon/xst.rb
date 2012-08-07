=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# Cross-Site tracing recon module.
#
# But not really...it only checks if the TRACE HTTP method is enabled.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/693.html
# @see http://capec.mitre.org/data/definitions/107.html
# @see http://www.owasp.org/index.php/Cross_Site_Tracing
#
class Arachni::Modules::XST < Arachni::Module::Base

    def self.ran?
        @ran ||= false
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        print_status( "Checking..." )

        http.trace( page.url, remove_id: true ) do |res|
            next if res.code != 200 || res.body.to_s.empty?

            log( { element: Element::SERVER }, res )
            print_ok "TRACE is enabled."
        end
    end

    def clean_up
        self.class.ran
    end

    def self.info
        {
            name:        'XST',
            description: %q{Sends an HTTP TRACE request and checks if it succeeded.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            references:  {
                'CAPEC' => 'http://capec.mitre.org/data/definitions/107.html',
                'OWASP' => 'http://www.owasp.org/index.php/Cross_Site_Tracing'
            },
            targets:     %w(Generic),
            issue:       {
                name:             %q{The TRACE HTTP method is enabled.},
                description:      %q{This type of attack can occur when the there
    is an XSS vulnerability and the server supports HTTP TRACE.},
                tags:             %w(xst methods trace server),
                cwe:              '693',
                severity:         Severity::MEDIUM,
                remedy_guidance:  %q{Disable TRACE method if not required or use input/output validation.}
            }

        }
    end

end
