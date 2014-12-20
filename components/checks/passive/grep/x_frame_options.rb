=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author  Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::XFrameOptions < Arachni::Check::Base

    def run
        return if audited?( page.parsed_url.host ) ||
            page.response.headers['X-Frame-Options']

        audited( page.parsed_url.host )

        log( vector: Element::Server.new( page.url ) )
    end

    def self.info
        {
            name:        'Missing X-Frame-Options header',
            description: %q{Checks the host for a missing X-Frame-Options header.},
            author:      'Tasos Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            elements:    [ Element::Server ],

            issue:       {
                name:        %q{Missing 'X-Frame-Options' header},
                description: %q{},
                references:  {
                    'MDN' => 'https://developer.mozilla.org/en-US/docs/Web/HTTP/X-Frame-Options',
                    'RFC' => 'http://tools.ietf.org/html/rfc7034'
                },
                severity:    Severity::LOW,
                remedy_guidance: %q{}
            }
        }
    end

end
