=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author  Tasos Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::HTTPSStrictTransportSecurity < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.parsed_url.scheme != 'https' ||
            page.response.headers['Strict-Transport-Security']

        audited( page.parsed_url.host )

        log( vector: Element::Server.new( page.url ) )
    end

    def self.info
        {
            name:        'HTTP Strict Transport Security',
            description: %q{Checks HTTPS pages for missing 'Strict-Transport-Security' headers.},
            author:      'Tasos Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Missing 'Strict-Transport-Security' header},
                description: %q{The web application uses HTTPS without specifying a 'Strict-Transport-Security' header.},
                references:  {
                    'OWASP'     => 'https://www.owasp.org/index.php/HTTP_Strict_Transport_Security',
                    'Wikipedia' => 'http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security'
                },
                cwe:         200,
                severity:    Severity::MEDIUM
            }
        }
    end

end
