=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::InsecureCORSPolicy < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.response.headers['Access-Control-Allow-Origin'] != '*'

        audited( page.parsed_url.host )

        log( vector: Element::Server.new( page.url ) )
    end

    def self.info
        {
            name:        'Insecure CORS policy',
            description: %q{Checks the host for a wildcard (`*`) `Access-Control-Allow-Origin` header.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Missing 'Access-Control-Allow-Origin' header},
                description: %q{},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/CORS_OriginHeaderScrutiny'
                },
                severity:    Severity::LOW,
                remedy_guidance: %q{}
            }
        }
    end

end
