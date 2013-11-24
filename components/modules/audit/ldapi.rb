=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# LDAP injection audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
# @see http://cwe.mitre.org/data/definitions/90.html
# @see http://projects.webappsec.org/w/page/13246947/LDAP-Injection
# @see http://www.owasp.org/index.php/LDAP_injection
#
class Arachni::Modules::LDAPInjection < Arachni::Module::Base

    def self.error_strings
        @errors ||= read_file( 'errors.txt' )
    end

    def run
        # This string will hopefully force the webapp to output LDAP error messages
        audit( "#^($!@$)(()))******",
            format:    [Format::APPEND],
            substring: self.class.error_strings
        )
    end

    def self.info
        {
            name:        'LDAPInjection',
            description: %q{It tries to force the web application to
                return LDAP error messages in order to discover failures
                in user input validation.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            references:  {
                'WASC'  => 'http://projects.webappsec.org/w/page/13246947/LDAP-Injection',
                'OWASP' => 'http://www.owasp.org/index.php/LDAP_injection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{LDAP Injection},
                description:     %q{LDAP queries can be injected into the web application
    which can be used to disclose sensitive data of affect the execution flow.},
                tags:            %w(ldap injection regexp),
                cwe:             '90',
                severity:        Severity::HIGH,
                cvssv2:          '',
                remedy_guidance: %q{User inputs must be validated and filtered
    before being used in an LDAP query.},
                remedy_code:     ''
            }

        }
    end

end
