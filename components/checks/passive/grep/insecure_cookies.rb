=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::InsecureCookies < Arachni::Check::Base

    def run
        return if page.parsed_url.scheme != 'https'

        # Page#cookies will also include stuff from the cookiejar, we only want
        # cookies for this page.
        (page.dom.cookies | page.parser.cookies).each do |cookie|
            next if cookie.secure? || audited?( cookie.name )

            log( vector: cookie )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Insecure cookies',
            description: %q{
Logs cookies that are served over an encrypted channel but without having the
`secure` flag set.
},
            elements:    [ Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.5',

            issue:       {
                name:            %q{Insecure cookie},
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

One of these flags is known as the `secure` flag. When the secure flag is set,
the browser will prevent it from being sent over a clear text channel (HTTP) and
only allow it to be sent when an encrypted channel is used (HTTPS).

Arachni discovered that a cookie was set by the server without the secure flag
being set. Although the initial setting of this cookie was via an HTTPS
connection, any HTTP link to the same server will result in the cookie being
send in clear text.
},
                references:  {
                    'SecureFlag - OWASP' => 'https://www.owasp.org/index.php/SecureFlag'
                },
                cwe:             200,
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{
The initial steps to remedy this should be determined on whether the cookie is
sensitive in nature.
If the cookie does not contain any sensitive information then the risk of this
vulnerability is reduced; however, if the cookie does contain sensitive
information, then the server should ensure that the cookie has its `secure` flag set.
}
            }
        }
    end

end
