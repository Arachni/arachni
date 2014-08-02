=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# SQL Injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://unixwiz.net/techtips/sql-injection.html
# @see http://en.wikipedia.org/wiki/SQL_injection
# @see http://www.securiteam.com/securityreviews/5DP0N1P76E.html
# @see http://www.owasp.org/index.php/SQL_Injection
class Arachni::Checks::SQLInjection < Arachni::Check::Base

    def self.error_patterns
        return @error_patterns if @error_patterns

        @error_patterns = {}
        Dir[File.dirname( __FILE__ ) + '/sqli/patterns/*'].each do |file|
            @error_patterns[File.basename( file ).to_sym] =
                IO.read( file ).split( "\n" ).map do |pattern|
                    Regexp.new( pattern, Regexp::IGNORECASE )
                end
        end

        @error_patterns
    end

    def self.ignore_patterns
        @ignore_patterns ||= read_file( 'regexp_ignore.txt' )
    end

    # Prepares the payloads that will hopefully cause the webapp to output SQL
    # error messages if included as part of an SQL query.
    def self.payloads
        @payloads ||= [ '\'`--', ')' ]
    end

    def self.options
        @options ||= {
            format:                    [Format::APPEND],
            regexp:                    error_patterns,
            ignore:                    ignore_patterns,
            param_flip:                true,
            longest_word_optimization: true
        }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'SQL Injection',
            description: %q{SQL injection check, uses known SQL DB errors to identify vulnerabilities.},
            elements:    [Element::Link, Element::Form, Element::Cookie,
                          Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',
            platforms:   options[:regexp].keys,

            issue:       {
                name:            %q{SQL Injection},
                description:     %q{SQL code can be injected into the web application.},
                references:  {
                    'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                    'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                    'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                    'OWASP'      => 'http://www.owasp.org/index.php/SQL_Injection'
                },
                tags:            %w(sql injection regexp database error),
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in database queries.'
            }
        }
    end

end
