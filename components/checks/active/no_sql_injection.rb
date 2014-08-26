=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::NoSqlInjection < Arachni::Check::Base

    def self.error_patterns
        return @error_patterns if @error_patterns

        @error_patterns = {}
        Dir[File.dirname( __FILE__ ) + '/no_sql_injection/patterns/*'].each do |file|
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
        @payloads ||= [ '\';.")' ]
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
            name:        'NoSQL Injection',
            description: %q{
NoSQL injection check, uses known DB errors to identify vulnerabilities.
},
            elements:    [Element::Link, Element::Form, Element::Cookie,
                          Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            platforms:   options[:regexp].keys,

            issue:       {
                name:            %q{NoSQL Injection},
                description:     %q{
A NoSQL injection occurs when a value originating from the client's request is
used within a NoSQL call without prior sanitisation.

This can allow cyber-criminals to execute arbitrary NoSQL code and thus steal data,
or use the additional functionality of the database server to take control of
further server components.

Arachni discovered that the affected page and parameter are vulnerable. This
injection was detected as Arachni was able to discover known error messages within
the server's response.
},
                tags:            %w(nosql injection regexp database error),
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Testing_for_NoSQL_injection'
                },
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The most effective remediation against NoSQL injection attacks is to ensure that
NoSQL API calls are not constructed via string concatenation that includes
unsanitized data.

Sanitization is best achieved using existing escaping libraries.
}
            }
        }
    end

end
