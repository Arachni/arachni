=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Private IP address recon check.
#
# Scans for private IP addresses.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version  0.3
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
            author:      'Tasos Laskos <tasos.laskos@gmail.com>',
            version:     '0.3',
            elements:    [ Element::Body, Element::Header ],

            issue:       {
                name:            %q{Private IP address disclosure},
                description:     %q{A private IP address is disclosed in the body of the HTML page},
                references: {
                    'WebAppSec' => 'http://projects.webappsec.org/w/page/13246936/Information%20Leakage'
                },
                cwe:             200,
                severity:        Severity::LOW,
                remedy_guidance: %q{Remove private IP addresses from the body of the HTML pages.},
            }
        }
    end

end
