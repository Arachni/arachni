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
# Private IP address recon module.
#
# Scans for private IP addresses.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version  0.2.2
#
class Arachni::Modules::PrivateIP < Arachni::Module::Base

    def self.regexp
        @regexp ||= /(?<!\.)(?<!\d)(?:(?:10|127)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|192\.168|169\.254|172\.0?(?:1[6-9]|2[0-9]|3[01]))(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}(?!\d)(?!\.)/
    end

    def run
        match_and_log( self.class.regexp )
    end

    def self.info
        {
            name:        'Private IP address finder',
            description: %q{Scans pages for private IP addresses.},
            author:      'Tasos Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.2',
            targets:     %w(Generic),
            elements:    [ Element::BODY, Element::HEADER ],
            references: {
                'WASC' => 'http://projects.webappsec.org/w/page/13246936/Information%20Leakage'
            },
            issue:       {
                name:            %q{Private IP address disclosure},
                description:     %q{Private IP's, or non-routable IP address' 
                    are generally used within a home or company network, and are 
                    typically unknown to anyone outside of that network. 
                    Cyber-criminals will attempt to identify the private IP 
                    address range being used by their victim to aid in any 
                    further information collection that could then lead to 
                    possible compromise. Arachni discovered that the affected 
                    page returned a RFC 1918 compliant private IP address, and 
                    therefor could be revealing sensitive information. This 
                    finding typically requires manual verification to ensure the 
                    context of this finding is correct. As any private IP 
                    address within the HTML body will trigger this finding},
                cwe:             '200',
                severity:        Severity::LOW,
                remedy_guidance: %q{Identifying the context in which the 
                    identified page displays a Private IP is required. If the 
                    page is publically accessible, and displaying the Private IP 
                    of the affected server (or supporting infrastructure) then 
                    measures should be put in place to ensure that the IP is 
                    removed from any response.},
            }
        }
    end

end
