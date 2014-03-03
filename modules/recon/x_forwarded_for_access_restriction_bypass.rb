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

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2
class Arachni::Modules::XForwardedAccessRestrictionBypass < Arachni::Module::Base

    def run
        return if ![401, 403].include?( page.code )
        http.get( page.url, headers: { 'X-Forwarded-For' => '127.0.0.1' } ) do |res|
            check_and_log( res )
        end
    end

    def check_and_log( res )
        return if res.code != 200
        log( { element: Element::SERVER }, res )
        print_ok "Request was accepted: #{res.effective_url}"
    end

    def self.info
        {
            name:        'X-Forwarded-For Access Restriction Bypass',
            description: %q{Retries denied requests with a X-Forwarded-For header
                to trick the web application into thinking that the request originates
                from localhost and checks whether the restrictions was bypassed.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            targets:     %w(Generic),
            references:  {
                'owasp'  => 'www.owasp.org/index.php/Session_Management_Cheat_Sheet',
            },

            issue:       {
                name:        %q{Access restriction bypass via X-Forwarded-For},
                description: %q{The X-Forwarded-For header is utilised by 
                    proxies and/or load balancers to track the originating IP 
                    address of the client. As the request progresses through a 
                    proxy, the X-Forwarded-For header is added to the existing 
                    headers, and the value of the client's IP is then set within
                    this header. Occasionally, poorly implemented access 
                    restrictions are based off of the originating IP address 
                    alone. For example, any public IP address may be forced to
                    authenticate, while an internal IP address may not. Because
                    this header can also be set by the client, it allows cyber-
                    criminals to spoof their IP address and potentially gain 
                    access to restricted pages. Arachni discovered a resource 
                    that it did not have permission to access, but been granted
                    access after spoofing the address of localhost (127.0.0.1),
                    thus bypassing any requirement to authenticate.},
                tags:        %w(access restriction server bypass),
                severity:    Severity::HIGH,
                remedy_guidance: %q{Remediation actions may be vastly different 
                    depending on the framework being used, and how the 
                    application has been coded. However, the X-Forwarded-For 
                    header should never be used to validate a client's access 
                    as it is trivial to change.}
            }
        }
    end

end
