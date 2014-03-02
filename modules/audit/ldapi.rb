=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

#
# LDAP injection audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
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
            version:     '0.1.3',
            references:  {
                'WASC'  => 'http://projects.webappsec.org/w/page/13246947/LDAP-Injection',
                'OWASP' => 'http://www.owasp.org/index.php/LDAP_injection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{LDAP Injection},
                description:     %q{Lightweight Directory Access Protocol (LDAP) 
                    is used by web applications to access and maintain directory 
                    information services. One of the most common uses for LDAP 
                    is to provide a single sign on service that will allow 
                    clients to authenticate with a web site without any 
                    interaction (assuming their credentials have been validated 
                    by another service). LDAP injection occurs when untrusted 
                    data is used by the web application ti queries the LDAP 
                    directory without prior sanitisation. This is a serious 
                    security risk, as it could allow cyber-criminals the ability 
                    to query, modify, or remove anything from the LDAP tree. It 
                    could also allow other advanced injection techniques that 
                    perform other more serious attacks. Arachni was able to 
                    detect a page that is vulnerable to LDAP injection.},
                tags:            %w(ldap injection regexp),
                cwe:             '90',
                severity:        Severity::HIGH,
                cvssv2:          '',
                remedy_guidance: %q{It is recommended that untrusted or 
                    invalidated data is never used to form a LDAP query. To 
                    validate data, the application should ensure that the 
                    supplied value contains only the characters that are 
                    required to perform the required action. For example, where 
                    a username is required, then no non-alpha characters should 
                    be accepted. If this is not possible, then special 
                    characters should be escaped so they are treated 
                    accordingly. The following characters should be escaped with 
                    a '\' backslash; Ampersand, exclamation mark, pipe, equals, 
                    less than, greater than, comma, plus, minus, double quote, 
                    single quote, and semicolon. Additional character filtering 
                    must be applied to; Open round bracket, close round bracket, 
                    backslash, asterisks, forward slash, NUL. These characters 
                    require ASCII escaping.},
                remedy_code:     ''
            }

        }
    end

end
