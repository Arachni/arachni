=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::CookieSetForParentDomain < Arachni::Check::Base

    def run
        page.cookies.each do |cookie|
            next if !cookie.domain.start_with?( '.' ) || audited?( cookie.name )

            log( vector: cookie )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Cookie set for parent domain',
            description: %q{Logs cookies that are accessible by all subdomains.},
            elements:    [ Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:        %q{Cookie set for parent domain},
                description: %q{The logged cookie will be made available to all subdomains.},
                cwe:         200,
                severity:    Severity::INFORMATIONAL
            }
        }
    end

end
