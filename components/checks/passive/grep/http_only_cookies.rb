=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Logs cookies that are accessible via JavaScript.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::HttpOnlyCookies < Arachni::Check::Base

    def run
        # We grab the parser cookies because the Page#cookies will also include
        # stuff from the cookiejar.
        page.parser.cookies.each do |cookie|
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.5',

            issue:       {
                name:            %q{HttpOnly cookie},
                description:     %q{
HTTP by itself is a stateless protocol. Therefore the server is unable to determine
which requests are performed by which client, and which clients are authenticated
or unauthenticated.

The use of HTTP cookies within the headers, allows a web server to identify each
individual client and can therefore determine which clients hold valid
authentication, from those that do not. These are known as session cookies.

When a cookie is set by the server (sent the header of an HTTP response) there
are several flags that can be set to configure the properties of the cookie and
how it is to be handled by the browser.

The `HttpOnly` flag assists in the prevention of client side-scripts (such as
JavaScript) accessing and using the cookie.

This can help prevent XSS attacks targeting the cookies holding the client's
session token (setting the `HttpOnly` flag does not prevent, nor safeguard against
XSS vulnerabilities themselves).
},
                references:  {
                    'HttpOnly - OWASP' => 'https://www.owasp.org/index.php/HttpOnly'
                },
                cwe:             200,
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{
The initial step to remedy this would be to determine whether any client-side
scripts (such as JavaScript) need to access the cookie and if not, set the
`HttpOnly` flag.

Additionally, it should be noted that some older browsers are not compatible with
the `HttpOnly` flag, and therefore setting this flag will not protect those clients
against this form of attack.
}
            }
        }
    end

end
