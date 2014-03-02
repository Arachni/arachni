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
# Logs cookies that are accessible via JavaScript.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::HttpOnlyCookies < Arachni::Module::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.http_only? || audited?( cookie.name )

            log( var: cookie.name, element: cookie.type, )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'HttpOnly cookies',
            description: %q{Logs cookies that are accessible via JavaScript.},
            elements:    [ Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            targets:     %w(Generic),
            references:  {
                'OWASP' => 'https://www.owasp.org/index.php/HttpOnly'
            },
            issue:       {
                name:            %q{HttpOnly cookie},
                description:     %q{HTTP by itself is a stateless protocol. 
                    Therefor the server is unable to determine which requests 
                    are performed by which client, and which clients are 
                    authenticated or unauthenticated. The use of HTTP cookies 
                    within the headers, allows a web server to identify each 
                    individual client, and can therefor determine which clients 
                    hold valid authentication from those that do not.  These are 
                    known as session cookies. When a cookie is set by the server 
                    (send the header of response) there are several flags that 
                    can be set to determine the properties of the cookie, and 
                    how it is handled by the browser. The HttpOnly flag assists 
                    in the prevention of client side scripts (such as 
                    JavaScript) accessing, and using the cookie. This can help 
                    preventing XSS attacks targeting the cookies holding the 
                    clients session token (Setting the HttpOnly flag does not 
                    prevent, or remediate against XSS vulnerabilities 
                    themselves). },
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{The initial steps to remediate this should 
                    be determined on whether any client side scripts (such as 
                    JavaScript) are required to access to cookie. If this cannot 
                    be determined, then it is likely not required by the scripts 
                    and should therefor have the HttpOnly flag as per the 
                    following remediation actions. The server should ensure that 
                    the cookie has its HttpOnly flag set. An example of this is 
                    as a server header is 'Set-Cookie: NAME=VALUE; HttpOnly'. 
                    Depending on the framework and server in use by the affected 
                    page, the technical remediation actions will differ. 
                    Instructions on specific framework remediation are available 
                    at 'www.owasp.org/index.php/HttpOnly'. Additionally, it 
                    should be noted that some older browsers are not compatible 
                    with the HttpOnly flag, and therefor setting this flag will 
                    not protect those clients against this form of attack.},
            }
        }
    end

end
