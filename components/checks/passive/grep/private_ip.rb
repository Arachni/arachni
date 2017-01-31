=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Private IP address recon check.
#
# Scans for private IP addresses.
#
# @author   Tasos Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::PrivateIP < Arachni::Check::Base

    def self.regexp
        @regexp ||= /(?<!\.)(?<!\d)(?:(?:10|127)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|192\.168|169\.254|172\.0?(?:1[6-9]|2[0-9]|3[01]))(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}(?!\d)(?!\.)/
    end

    def run
        match_and_log( self.class.regexp )

        page.response.headers.each do |k, v|
            next if !(v =~ self.class.regexp)
            log(
                vector: Element::Header.new( url: page.url, inputs: { k => v } ),
                proof:  v
            )
        end
    end

    def self.info
        {
            name:        'Private IP address finder',
            description: %q{Scans pages for private IP addresses.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3',
            elements:    [ Element::Body, Element::Header ],

            issue:       {
                name:            %q{Private IP address disclosure},
                description:     %q{
Private, or non-routable, IP addresses are generally used within a home or
company network and are typically unknown to anyone outside of that network.

Cyber-criminals will attempt to identify the private IP address range being used
by their victim, to aid in collecting further information that could then lead
to a possible compromise.

Arachni discovered that the affected page returned a RFC 1918 compliant private
IP address and therefore could be revealing sensitive information.

_This finding typically requires manual verification to ensure the context is
correct, as any private IP address within the HTML body will trigger it.
},
                references: {
                    'WebAppSec' => 'http://projects.webappsec.org/w/page/13246936/Information%20Leakage'
                },
                cwe:             200,
                severity:        Severity::LOW,
                remedy_guidance: %q{
Identifying the context in which the affected page displays a Private IP
address is necessary.

If the page is publicly accessible and displays the Private IP of the affected
server (or supporting infrastructure), then measures should be put in place to
ensure that the IP address is removed from any response.
},
            }
        }
    end

end
