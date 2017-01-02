=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.3
class Arachni::Checks::Hsts < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.parsed_url.scheme != 'https' ||
            page.response.headers.empty? ||
            page.response.headers['Strict-Transport-Security']

        audited( page.parsed_url.host )

        log(
            vector: Element::Server.new( page.url ),
            proof:  page.response.status_line
        )
    end

    def self.info
        {
            name:        'HTTP Strict Transport Security',
            description: %q{Checks HTTPS pages for missing `Strict-Transport-Security` headers.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.3',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Missing 'Strict-Transport-Security' header},
                description: %q{
The HTTP protocol by itself is clear text, meaning that any data that is
transmitted via HTTP can be captured and the contents viewed. To keep data
private and prevent it from being intercepted, HTTP is often tunnelled through
either Secure Sockets Layer (SSL) or Transport Layer Security (TLS).
When either of these encryption standards are used, it is referred to as HTTPS.

HTTP Strict Transport Security (HSTS) is an optional response header that can be
configured on the server to instruct the browser to only communicate via HTTPS.
This will be enforced by the browser even if the user requests a HTTP resource
on the same server.

Cyber-criminals will often attempt to compromise sensitive information passed
from the client to the server using HTTP. This can be conducted via various
Man-in-The-Middle (MiTM) attacks or through network packet captures.

Arachni discovered that the affected application is using HTTPS however does not
use the HSTS header.
},
                references:  {
                    'OWASP'     => 'https://www.owasp.org/index.php/HTTP_Strict_Transport_Security',
                    'Wikipedia' => 'http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security'
                },
                cwe:         200,
                severity:    Severity::MEDIUM,
                remedy_guidance: %q{
Depending on the framework being used the implementation methods will vary,
however it is advised that the `Strict-Transport-Security` header be configured
on the server.

One of the options for this header is `max-age`, which is a representation (in
milliseconds) determining the time in which the client's browser will adhere to
the header policy.

Depending on the environment and the application this time period could be from
as low as minutes to as long as days.
}
            }
        }
    end

end
