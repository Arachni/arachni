=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# Blind SQL Injection module using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class Arachni::Modules::BlindTimingSQLInjection < Arachni::Module::Base

    prefer :sqli

    def self.payloads
        @payloads ||= {
            mysql: read_file( 'mysql.txt' ),
            pgsql: read_file( 'pgsql.txt' ),
            mssql: read_file( 'mssql.txt' )
        }
    end

    def run
        audit_timeout self.class.payloads,
            format:          [Format::STRAIGHT, Format::APPEND],
            timeout:         4000,
            timeout_divider: 1000
    end

    def self.info
        {
            name:        'Blind SQL injection (timing attack)',
            description: %q{Blind SQL Injection module using timing attacks
                (if the remote server suddenly becomes unresponsive or your network
                connection suddenly chokes up this module will probably produce false positives).},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3',
            references:  {
                'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            targets:     %w(MySQL PostgreSQL MSSQL),
            issue:       {
                name:            %q{Blind SQL Injection (timing attack)},
                description:     %q{SQL code can be injected into the web application
    even though it may not be obvious due to suppression of error messages.
    (This issue was discovered using a timing attack; timing attacks
    can result in false positives in cases where the server takes
    an abnormally long time to respond.
    Either case, these issues will require further investigation
    even if they are false positives.)},
                tags:            %w(sql blind timing injection database),
                cwe:             '89',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{Suppression of error messages leads to
    security through obscurity which is not a good practise.
    The web application needs to enforce stronger validation
    on user inputs.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
