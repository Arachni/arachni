=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::NoSqlInjection < Arachni::Check::Base

    def self.error_signatures
        return @error_signatures if @error_signatures

        @error_signatures = {}
        Dir[File.dirname( __FILE__ ) + '/no_sql_injection/substrings/*'].each do |file|
            @error_signatures[File.basename( file ).to_sym] =
                IO.read( file ).split( "\n" )
        end

        @error_signatures
    end

    # Prepares the payloads that will hopefully cause the webapp to output SQL
    # error messages if included as part of an SQL query.
    def self.payloads
        @payloads ||= { mongodb: '\';.")' }
    end

    def self.options
        @options ||= {
            format:     [Format::APPEND],
            signatures: error_signatures
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
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.3',
            platforms:   payloads.keys,

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
