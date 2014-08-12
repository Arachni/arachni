=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Logs cookies that are accessible via JavaScript.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class Arachni::Checks::HttpOnlyCookies < Arachni::Check::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.http_only? || audited?( cookie.name )

            log( vector: cookie )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'HttpOnly cookies',
            description: %q{Logs cookies that are accessible via JavaScript.},
            elements:    [ Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',

            issue:       {
                name:            %q{HttpOnly cookie},
                description:     %q{
HTTP by itself is a stateless protocol.
Therefore the server is unable to determine which requests are performed by which
client, and which clients are authenticated or unauthenticated.

The use of HTTP cookies within the headers, allows a web server to identify each
individual client, and can therefor determine which clients hold valid
authentication from those that do not.

These are known as session cookies. When a cookie is set by the server there are
several flags that can be set to configure the properties of the cookie, and how
it is handled by the browser.

The `HttpOnly` flag assists in the prevention of client side scripts (such as
JavaScript) accessing, and using the cookie.

This can help preventing XSS attacks targeting the cookies holding the clients
session token (setting the `HttpOnly` flag does not prevent, nor safeguard against
XSS vulnerabilities themselves).
},
                references:  {
                    'HttpOnly - OWASP' => 'https://www.owasp.org/index.php/HttpOnly'
                },
                cwe:             200,
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{
The initial steps to remedy this should be determined on whether any client side
scripts (such as JavaScript) are required to access the cookie.

If this cannot be determined, then it is likely not required by the scripts and
should therefor have the `HttpOnly` flag as per the following remediation actions.
The server should ensure that the cookie has its `HttpOnly` flag set.
An example of this is as a server header is `Set-Cookie: NAME=VALUE; HttpOnly`.

Depending on the framework and server in use by the affected page, the technical
remediation actions will differ.

Additionally, it should be noted that some older browsers are not compatible with
the `HttpOnly` flag, and therefore setting this flag will not protect those clients
against this form of attack.
}
            }
        }
    end

end
