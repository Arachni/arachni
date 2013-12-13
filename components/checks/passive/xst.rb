=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Cross-Site tracing recon check.
#
# But not really...it only checks if the TRACE HTTP method is enabled.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/693.html
# @see http://capec.mitre.org/data/definitions/107.html
# @see http://www.owasp.org/index.php/Cross_Site_Tracing
class Arachni::Checks::XST < Arachni::Check::Base

    def self.ran?
        @ran ||= false
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        print_status 'Checking...'

        http.trace( page.url ) do |response|
            next if response.code != 200 || response.body.to_s.empty?

            log( { vector: Element::Server.new( response ) }, response )
            print_ok 'TRACE is enabled.'
        end
    end

    def clean_up
        self.class.ran
    end

    def self.info
        {
            name:        'XST',
            description: %q{Sends an HTTP TRACE request and checks if it succeeded.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            targets:     %w(Generic),

            issue:       {
                name:            %q{HTTP TRACE},
                description:     %q{The HTTP TRACE method is enabled.
    This misconfiguration can become a pivoting point for a Cross-Site Scripting (XSS) attack.},
                references:  {
                    'CAPEC' => 'http://capec.mitre.org/data/definitions/107.html',
                    'OWASP' => 'http://www.owasp.org/index.php/Cross_Site_Tracing'
                },
                tags:            %w(xst methods trace server),
                cwe:             693,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Disable the TRACE method if not required or use input/output validation.}
            }

        }
    end

end
