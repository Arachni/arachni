=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Blind SQL Injection check using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Checks::BlindTimingSQLInjection < Arachni::Check::Base

    prefer :sqli, :sqli_blind_differential

    def self.payloads
        @payloads ||= {
            mysql: read_file( 'mysql.txt' ),
            pgsql: read_file( 'pgsql.txt' ),
            mssql: read_file( 'mssql.txt' )
        }.inject({}){ |h, (k,v)| h.merge( k => v.map { |s| s.gsub( '[space]', ' ' ) } ) }
    end

    def run
        audit_timeout self.class.payloads,
            format:          [Format::APPEND],
            timeout:         4000,
            timeout_divider: 1000
    end

    def self.info
        {
            name:        'Blind SQL injection (timing attack)',
            description: %q{Blind SQL Injection check using timing attacks
                (if the remote server suddenly becomes unresponsive or your network
                connection suddenly chokes up this check will probably produce false positives).},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3.2',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Blind SQL Injection (timing attack)},
                description:     %q{SQL code can be injected into the web application
    even though it may not be obvious due to suppression of error messages.
    (This issue was discovered using a timing attack; timing attacks
    can result in false positives in cases where the server takes
    an abnormally long time to respond.
    Either case, these issues will require further investigation
    even if they are false positives.)},
                references:  {
                    'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                    'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
                },
                tags:            %w(sql blind timing injection database),
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{Suppression of error messages leads to
    security through obscurity which is not a good practise.
    The web application needs to enforce stronger validation
    on user inputs.}
            }

        }
    end

end
