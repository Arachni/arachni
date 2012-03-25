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

module Arachni
module Modules

#
# Cross-Site tracing recon module.
#
# But not really...it only checks if the TRACE HTTP method is enabled.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/693.html
# @see http://capec.mitre.org/data/definitions/107.html
# @see http://www.owasp.org/index.php/Cross_Site_Tracing
#
class XST < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        # we need to run only once
        @@__ran ||= false
    end

    def run
        return if @@__ran

        print_status( "Checking..." )

        @http.trace( URI( normalize_url( @page.url ) ).host ).on_complete {
            |res|
            # checking for a 200 code is not enought, there are some weird
            # webservers out there that don't give a flying fuck about standards
            __log_results( res ) if res.code == 200 && !res.body.empty?
        }

    end

    def clean_up
        @@__ran = true
    end

    def self.info
        {
            :name           => 'XST',
            :description    => %q{Sends an HTTP TRACE request and checks if it succeeded.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
            :references     => {
                'CAPEC'     => 'http://capec.mitre.org/data/definitions/107.html',
                'OWASP'     => 'http://www.owasp.org/index.php/Cross_Site_Tracing'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{The TRACE HTTP method is enabled.},
                :description => %q{This type of attack can occur when the there
                    is an XSS vulnerability and the server supports HTTP TRACE. },
                :tags        => [ 'xst', 'methods', 'trace', 'server' ],
                :cwe         => '693',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        # inform the user that we have a match
        print_ok( "TRACE is enabled." )
    end

end
end
end
