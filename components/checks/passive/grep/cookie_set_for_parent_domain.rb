=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.2
class Arachni::Checks::CookieSetForParentDomain < Arachni::Check::Base

    def run
        return if !page.parser

        page.parser.cookies.each do |cookie|
            next if !cookie.domain.start_with?( '.' ) || audited?( cookie.name )

            log( vector: cookie, proof: cookie.domain )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Cookie set for parent domain',
            description: %q{Logs cookies that are accessible by all subdomains.},
            elements:    [ Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',

            issue:       {
                name:        %q{Cookie set for parent domain},
                description: %q{
HTTP by itself is a stateless protocol. Therefore the server is unable to determine
which requests are performed by which client, and which clients are authenticated
or unauthenticated.

The use of HTTP cookies within the headers, allows a web server to identify each
individual client and can therefore determine which clients hold valid
authentication, from those that do not. These are known as session cookies.

When a cookie is set by the server (sent the header of an HTTP response) there
are several flags that can be set to configure the properties of the cookie and
how it is to be handled by the browser.

One of these flags represents the host, or domain. for which the cookie can be used.

When the cookie is set for the parent domain, rather than the host, this could
indicate that the same cookie could be used to access other hosts within that domain.
While there are many legitimate reasons for this, it could also be misconfiguration
expanding the possible surface of attacks.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Testing_for_cookies_attributes_(OTG-SESS-002)'
                },
                cwe:         200,
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{
The first step to remediation is to identify the context in which the cookie is
being set and determine if it is required by the whole domain, or just the
specific host being tested.

If it is only required by the host, then the domain flag should be set as such.

Depending on the framework being used, the configuration of this flag will be
modified in different ways.
}
            }
        }
    end

end
