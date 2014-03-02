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
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::InsecureCookies < Arachni::Module::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.secure? || audited?( cookie.name )

            log( var: cookie.name, element: cookie.type, )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Insecure cookies',
            description: %q{Logs cookies that are served over an unencrypted channel.},
            elements:    [ Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            targets:     %w(Generic),
            references:  {
                'OWASP' => 'https://www.owasp.org/index.php/SecureFlag'
            },
            issue:       {
                name:            %q{Insecure cookie},
                description:     %q{HTTP by itself is a stateless protocol. 
                    Therefor the server is unable to determine which requests 
                    are performed by which client, and which clients are 
                    authenticated or unauthenticated. The use of HTTP cookies 
                    within the headers, allows a web server to identify each 
                    individual client, and can therefor determine which clients 
                    hold valid authentication from those that do not. These are 
                    known as session cookies. Because these cookies are used to 
                    store a client's session (authenticated or unauthenticated), 
                    it is important that the cookie is passed via an encrypted 
                    channel. When a cookie is set by the server (send from the 
                    server to the client in the header of response) there are 
                    several flags that can be set to determine the properties of 
                    the cookie, and how it is to handle by the browser. One of 
                    these flags is known as the 'secure' flag. When the secure 
                    flag is set, the browser will prevent it being send over any 
                    clear text channel (HTTP), and only allow it to be sent when 
                    an encrypted channel is used (HTTPS). Arachni discovered 
                    that a cookie, and possible session token was set by the 
                    server without the secure flag being set. Although the 
                    initial setting of this cookie was via a HTTPS connection, 
                    any HTTP link to the same server will result in the cookie 
                    being send in clear text.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{The initial steps to remediate this should 
                    be determined on whether the cookie is sensitive in nature, 
                    or is used to store a session token. If the cookie does not 
                    contain any sensitive information then the risk of this 
                    vulnerability is reduced, however if the cookie does contain 
                    sensitive information, then the server should ensure that 
                    the cookie has its secure flag set. An example of this is as 
                    a server header is 'Set-Cookie: NAME=VALUE; secure'. 
                    Depending on the framework and server in use by the affected 
                    page, the technical remediation actions will differ. 
                    Instructions on specific framework remediation are available 
                    at 'www.owasp.org/index.php/SecureFlag'},
            }
        }
    end

end
