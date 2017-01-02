=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# LDAP injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/90.html
# @see http://projects.webappsec.org/w/page/13246947/LDAP-Injection
# @see https://www.owasp.org/index.php/LDAP_injection
class Arachni::Checks::LdapInjection < Arachni::Check::Base

    def self.error_strings
        @errors ||= read_file( 'errors.txt' )
    end

    def run
        # This string will hopefully force the webapp to output LDAP error messages.
        audit( '#^($!@$)(()))******',
            format:     [Format::APPEND],
            signatures: self.class.error_strings
        )
    end

    def self.info
        {
            name:        'LDAPInjection',
            description: %q{
It tries to force the web application to return LDAP error messages, in order to
discover failures in user input validation.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.4',

            issue:       {
                name:            %q{LDAP Injection},
                description:     %q{
Lightweight Directory Access Protocol (LDAP) is used by web applications to access
and maintain directory information services.

One of the most common uses for LDAP is to provide a Single-Sign-On (SSO) service
that will allow clients to authenticate with a web site without any interaction
(assuming their credentials have been validated by the SSO provider).

LDAP injection occurs when untrusted data is used by the web application to query
the LDAP directory without prior sanitisation.

This is a serious security risk, as it could allow cyber-criminals the ability
to query, modify, or remove anything from the LDAP tree. It could also allow other
advanced injection techniques that perform other more serious attacks.

Arachni was able to detect a page that is vulnerable to LDAP injection based on
known error messages.
},
                tags:            %w(ldap injection regexp),
                references:  {
                    'WASC'  => 'http://projects.webappsec.org/w/page/13246947/LDAP-Injection',
                    'OWASP' => 'https://www.owasp.org/index.php/LDAP_injection'
                },
                cwe:             90,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a LDAP query.

To validate data, the application should ensure that the supplied value contains
only the characters that are required to perform the required action. For example,
where a username is required, then no non-alphanumeric characters should be accepted.

If this is not possible, special characters should be escaped so they are treated
accordingly. The following characters should be escaped with a `\`:

* `&`
* `!`
* `|`
* `=`
* `<`
* `>`
* `,`
* `+`
* `-`
* `"`
* `'`
* `;`

Additional character filtering must be applied to:

* `(`
* `)`
* `\`
* `/`
* `*`
* `NULL`

These characters require ASCII escaping.
}
            }
        }
    end

end
