=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# SQL Injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://unixwiz.net/techtips/sql-injection.html
# @see http://en.wikipedia.org/wiki/SQL_injection
# @see http://www.securiteam.com/securityreviews/5DP0N1P76E.html
# @see https://www.owasp.org/index.php/SQL_Injection
class Arachni::Checks::SqlInjection < Arachni::Check::Base

    def self.error_signatures
        return @error_signatures if @error_signatures

        @error_signatures = {}

        Dir[File.dirname( __FILE__ ) + '/sql_injection/substrings/*'].each do |file|
            @error_signatures[File.basename( file ).to_sym] =
                IO.read( file ).split( "\n" )
        end

        Dir[File.dirname( __FILE__ ) + '/sql_injection/regexps/*'].each do |file|
            platform = File.basename( file, '.yaml' ).to_sym

            @error_signatures[platform] ||= []

            YAML.load_file( file ).each do |substring, pattern|
                regexp = Regexp.new( pattern )

                @error_signatures[platform] << proc do |response|
                    next if !response.body.include?( substring )
                    regexp
                end
            end
        end

        @error_signatures
    end

    def self.ignore_signatures
        @ignore_signatures ||= read_file( 'ignore_substrings' )
    end

    # Prepares the payloads that will hopefully cause the webapp to output SQL
    # error messages if included as part of an SQL query.
    def self.payloads
        @payloads ||= [ '"\'`--', ')' ]
    end

    def self.options
        @options ||= {
            format:     [Format::APPEND],
            signatures: error_signatures,
            ignore:     ignore_signatures
        }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'SQL Injection',
            description: %q{
SQL injection check, uses known SQL DB errors to identify vulnerabilities.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.3',
            platforms:   options[:signatures].keys,

            issue:       {
                name:            %q{SQL Injection},
                description:     %q{
Due to the requirement for dynamic content of today's web applications, many
rely on a database backend to store data that will be called upon and processed
by the web application (or other programs).
Web applications retrieve data from the database by using Structured Query Language
(SQL) queries.

To meet demands of many developers, database servers (such as MSSQL, MySQL,
Oracle etc.) have additional built-in functionality that can allow extensive
control of the database and interaction with the host operating system itself.

An SQL injection occurs when a value originating from the client's request is used
within a SQL query without prior sanitisation. This could allow cyber-criminals
to execute arbitrary SQL code and steal data or use the additional functionality
of the database server to take control of more server components.

The successful exploitation of a SQL injection can be devastating to an
organisation and is one of the most commonly exploited web application vulnerabilities.

This injection was detected as Arachni was able to cause the server to respond to
the request with a database related error.
},
                references:  {
                    'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                    'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                    'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                    'OWASP'      => 'https://www.owasp.org/index.php/SQL_Injection',
                    'WASC'       => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                    'W3 Schools' => 'http://www.w3schools.com/sql/sql_injection.asp'
                },
                tags:            %w(sql injection regexp database error),
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The only proven method to prevent against SQL injection attacks while still
maintaining full application functionality is to use parameterized queries
(also known as prepared statements).
When utilising this method of querying the database, any value supplied by the
client will be handled as a string value rather than part of the SQL query.

Additionally, when utilising parameterized queries, the database engine will
automatically check to make sure the string being used matches that of the column.
For example, the database engine will check that the user supplied input is an
integer if the database column is configured to contain integers.
}
            }
        }
    end

end
