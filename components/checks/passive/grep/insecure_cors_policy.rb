=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.1
class Arachni::Checks::InsecureCORSPolicy < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.response.headers['Access-Control-Allow-Origin'] != '*'
        audited( page.parsed_url.host )

        log(
            vector: Element::Server.new( page.url ),
            proof:  page.response.headers_string[/Access-Control-Allow-Origin.*$/i]
        )
    end

    def self.info
        {
            name:        'Insecure CORS policy',
            description: %q{Checks the host for a wildcard (`*`) `Access-Control-Allow-Origin` header.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.1',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Insecure 'Access-Control-Allow-Origin' header},
                description: %q{
_Cross Origin Resource Sharing (CORS)_ is an HTML5 technology which gives modern
web browsers the ability to bypass restrictions implemented by the _Same Origin Policy_.
The _Same Origin Policy_ requires that both the JavaScript and the page are loaded
from the same domain in order to allow JavaScript to interact with the page. This
in turn prevents malicious JavaScript being executed when loaded from external domains.

The CORS policy allows the application to specify exceptions to the protections
implemented by the browser, and allows the developer to whitelist domains for
which external JavaScript is permitted to execute and interact with the page.

A weak CORS policy is one which whitelists all domains using a wildcard (`*`),
which will allow any externally loaded JavaScript resource to interact with the
affected page. This can severely increase the risk of attacks such as Cross Site Scripting etc.

Arachni detected that the CORS policy being set by the server was weak, and used
a wildcard value. This is evident by the `Access-Control-Allow-Origin` header being set to `*`.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/CORS_OriginHeaderScrutiny',
                    'Mozilla Developer Network' => 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS'
                },
                severity:    Severity::LOW,
                remedy_guidance: %q{
It is important that weak CORS policies are not used. Policies can be hardened by
removing the wildcard and individually specifying the domains where the trusted
JavaScript resources are located. If the list of hosts for externally hosted
JavaScript resources is excessive, then a whole top level domain can be whitelisted
by using a combination of the wildcard and the domain (example: `*.arachni-scanner.com`).
}
            }
        }
    end

end
