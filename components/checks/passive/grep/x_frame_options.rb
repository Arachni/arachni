=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.2
class Arachni::Checks::XFrameOptions < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.response.headers.empty? ||
            page.response.headers['X-Frame-Options']
        audited( page.parsed_url.host )

        log(
            vector: Element::Server.new( page.url ),
            proof:  page.response.status_line
        )
    end

    def self.info
        {
            name:        'Missing X-Frame-Options header',
            description: %q{Checks the host for a missing `X-Frame-Options` header.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Missing 'X-Frame-Options' header},
                description: %q{
Clickjacking (User Interface redress attack, UI redress attack, UI redressing)
is a malicious technique of tricking a Web user into clicking on something different
from what the user perceives they are clicking on, thus potentially revealing
confidential information or taking control of their computer while clicking on
seemingly innocuous web pages.

The server didn't return an `X-Frame-Options` header which means that this website
could be at risk of a clickjacking attack.

The `X-Frame-Options` HTTP response header can be used to indicate whether or not
a browser should be allowed to render a page inside a frame or iframe. Sites can
use this to avoid clickjacking attacks, by ensuring that their content is not
embedded into other sites.
},
                references:  {
                    'MDN'   => 'https://developer.mozilla.org/en-US/docs/Web/HTTP/X-Frame-Options',
                    'RFC'   => 'http://tools.ietf.org/html/rfc7034',
                    'OWASP' => 'https://www.owasp.org/index.php/Clickjacking'
                },
                cwe:         693,
                severity:    Severity::LOW,
                remedy_guidance: %q{
Configure your web server to include an `X-Frame-Options` header.
}
            }
        }
    end

end
