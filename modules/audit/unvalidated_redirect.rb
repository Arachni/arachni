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

# Unvalidated redirect audit module.
#
# It audits links, forms and cookies, injects URLs and checks the `Location`
# header field to determine whether the attack was successful.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
#
# @see http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
class Arachni::Modules::UnvalidatedRedirect < Arachni::Module::Base

    def self.payloads
        @payloads ||= [
            'www.arachni-boogie-woogie.com',
            'https://www.arachni-boogie-woogie.com',
            'http://www.arachni-boogie-woogie.com'
        ]
    end

    def run
        audit( self.class.payloads ) do |res, opts|
            next if !self.class.payloads.include?( res.location.to_s.downcase )
            log( opts, res )
        end
    end

    def self.info
        {
            name:        'Unvalidated redirect',
            description: %q{Injects URLs and checks the Location header field
                to determnine whether the attack was successful.},
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.6',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards',
                'WASC' => 'http://projects.webappsec.org/w/page/13246981/URL%20Redirector%20Abuse'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Unvalidated redirect},
                description:     %q{Web applications occasionally use
                    parameter values to store the address of the page to which
                    the client will be redirected. As an example, this is
                    often seen in error pages where the error page is the page 
                    to be displayed. For example 
                    'yoursite.com/page.asp?redirect=www.yoursite.com/404.asp'. 
                    An unvalidated redirect occurs when the client is able to
                    modify the affected parameter value in the request and have 
                    a redirect response to the new value sent by the server. 
                    Therefore, redirecting the client to that site. For example,
                    the following request 'yoursite.com/page.asp?redirect=www.anothersite.com'
                    will redirect to 'anothersite.com'. Cyber-criminals will abuse
                    these vulnerabilities in social engineering attacks to get 
                    users to unknowingly visit a malicious site hosted by the 
                    cyber-criminal. Arachni has discovered that the server does 
                    not validate the parameter value prior to redirecting the 
                    client to the injected value.},
                tags:            %w(unvalidated redirect injection header location),
                cwe:             '819',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{The application should ensure that the 
                    supplied value for a redirect is permitted. This can be 
                    achieved by performing whitelisting on the parameter value. 
                    The whitelist should contain a list of pages or sites that 
                    the application is permitted to redirect users to. If the 
                    supplied value does not match any value in the whitelist 
                    then the server should redirect to a standard error page.}
            }
        }
    end

end
