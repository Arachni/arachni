=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::OriginSpoofAccessRestrictionBypass < Arachni::Check::Base

    HEADERS = [
        'X-Forwarded-For',
        'X-Originating-IP',
        'X-Remote-IP',
        'X-Remote-Addr'
    ]

    ADDRESS = '127.0.0.1'

    def self.http_options
        @http_options ||= {
            headers: HEADERS.inject({}) { |h, header| h.merge( header => ADDRESS ) }
        }
    end

    def run
        return if ![401, 403].include?( page.code )

        http.get( page.url, self.class.http_options, &method(:check_and_log) )
    end

    def check_and_log( response )
        return if response.code != 200

        log(
            vector:   Element::Server.new( response.url ),
            response: response,
            proof:    response.status_line
        )
        print_ok "Request was accepted: #{response.url}"
    end

    def self.info
        {
            name:        'Origin Spoof Access Restriction Bypass',
            description: %q{Retries denied requests with a spoofed origin header
                to trick the web application into thinking that the request originated
                from localhost and checks whether the restrictions was bypassed.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',

            issue:       {
                name:        %q{Access restriction bypass via origin spoof},
                description: %q{
Origin headers are utilised by proxies and/or load balancers to track the
originating IP address of the client.

As the request progresses through a proxy, the origin header is added to the
existing headers, and the value of the client's IP is then set within this header.
Occasionally, poorly implemented access restrictions are based off of the
originating IP address alone.

For example, any public IP address may be forced to authenticate, while an
internal IP address may not.

Because this header can also be set by the client, it allows cyber-criminals to
spoof their IP address and potentially gain access to restricted pages.

Arachni discovered a resource that it did not have permission to access, but been
granted access after spoofing the address of localhost (127.0.0.1), thus bypassing
any requirement to authenticate.
},
                tags:        %w(access restriction server bypass),
                severity:    Severity::HIGH,
                remedy_guidance: %q{
Remediation actions may be vastly different depending on the framework being used,
and how the application has been coded. However, the origin header should never
be used to validate a client's access as it is trivial to change.
}
            }
        }
    end

end
