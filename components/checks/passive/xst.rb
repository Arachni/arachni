=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Cross-Site tracing recon check.
#
# But not really...it only checks if the TRACE HTTP method is enabled.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/693.html
# @see http://capec.mitre.org/data/definitions/107.html
# @see http://www.owasp.org/index.php/Cross_Site_Tracing
class Arachni::Checks::Xst < Arachni::Check::Base

    RAN = Set.new

    def self.ran_for?( proto )
        RAN.include? proto
    end

    def self.ran_for( proto )
        RAN << proto
    end

    def run
        return if self.class.ran_for?( page.parsed_url.scheme )
        self.class.ran_for( page.parsed_url.scheme )

        print_status 'Checking...'

        http.trace( page.url ) do |response|
            next if response.code != 200 || response.body.to_s.empty?

            log(
                vector:   Element::Server.new( response.url ),
                response: response,
                proof:    response.status_line
            )
        end
    end

    def self.info
        {
            name:        'XST',
            description: %q{Sends an HTTP TRACE request and checks if it succeeded.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.8',

            issue:       {
                name:            %q{HTTP TRACE},
                description:     %q{
The `TRACE` HTTP method allows a client so send a request to the server, and
have the same request then send back in the server's response. This allows the
client to determine if the server is receiving the request as expected or if
specific parts of the request are not arriving as expected.
For example incorrect encoding or a load balancer has filtered or changed a value.
On many default installations the `TRACE` method is still enabled.

While not vulnerable by itself, it does provide a method for cyber-criminals to
bypass the `HTTPOnly` cookie flag, and therefore could allow a XSS attack to
successfully access a session token.

Arachni has discovered that the affected page permits the HTTP `TRACE` method.
},
                references:  {
                    'CAPEC' => 'http://capec.mitre.org/data/definitions/107.html',
                    'OWASP' => 'http://www.owasp.org/index.php/Cross_Site_Tracing'
                },
                tags:            %w(xst methods trace server),
                cwe:             693,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
The HTTP `TRACE` method is normally not required within production sites and
should therefore be disabled.

Depending on the function being performed by the web application, the risk
level can start low and increase as more functionality is implemented.

The remediation is typically a very simple configuration change and in most cases
will not have any negative impact on the server or application.
}
            }
        }
    end

end
