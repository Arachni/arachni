=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Logs cookies that are accessible via JavaScript.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Checks::HttpOnlyCookies < Arachni::Check::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.http_only? || audited?( cookie.name )

            log( var: cookie.name, element: cookie.type, )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'HttpOnly cookies',
            description: %q{Logs cookies that are accessible via JavaScript.},
            elements:    [ Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            references:  {
                'HttpOnly - OWASP' => 'https://www.owasp.org/index.php/HttpOnly'
            },
            issue:       {
                name:            %q{HttpOnly cookie},
                description:     %q{The logged cookie does not have the HttpOnly
    flag set which makes it succeptible to maniplation via client-side code.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Set the 'HttpOnly' flag in the cookie.},
            }
        }
    end

end
