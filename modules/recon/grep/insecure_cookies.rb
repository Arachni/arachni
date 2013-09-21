=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Modules::InsecureCookies < Arachni::Module::Base

    def run
        page.cookies.each do |cookie|
            next if cookie.secure? || audited?( cookie.name )

            log( var: cookie.name, element: cookie.type, )
            audited( cookie.name )
        end
    end

    def self.info
        {
            name:        'Insecure cookies',
            description: %q{Logs cookies that are served over an unencrypted channel.},
            elements:    [ Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            references:  {
                'SecureFlag - OWASP' => 'https://www.owasp.org/index.php/SecureFlag'
            },
            issue:       {
                name:            %q{Insecure cookie},
                description:     %q{The logged cookie is allowed to be served over
    an unencrypted channel which makes it susceptible to sniffing.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Set the 'Secure' flag in the cookie.},
            }
        }
    end

end
