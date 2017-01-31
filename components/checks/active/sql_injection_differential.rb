=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Blind SQL injection check
#
# It uses differential analysis to determine how different inputs affect the
# behavior of the web application and checks if the displayed behavior is
# consistent with that of a vulnerable application
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see https://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Checks::SqlInjectionDifferential < Arachni::Check::Base

    prefer :sql_injection

    def self.queries_for_expression( expression )
        (@templates ||= read_file( 'payloads.txt' )).map do |template|
            [ '\'', '"', '' ].map do |quote|
                template.gsub( '%q%', quote ) + " #{expression.gsub( '%q%', quote )}"
            end
        end.flatten
    end

    # Options holding fault and boolean injection seeds.
    def self.options
        return @options if @options

        pairs  = []
        falses = queries_for_expression( '%q%1%q%=%q%2' )

        queries_for_expression( '%q%1%q%=%q%1' ).each.with_index do |true_expr, i|
            pairs << { true_expr => falses[i] }
        end

        @options = { false: '-1839', pairs: pairs }
    end

    def run
        audit_differential self.class.options
    end

    def self.info
        {
            name:        'Blind SQL Injection (differential analysis)',
            description: %q{
It uses differential analysis to determine how different inputs affect behavior
of the web application and checks if the displayed behavior is consistent with
that of a vulnerable application.
},
            elements:    [ Element::Link, Element::Form, Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.4.4',
            platforms:   [ :sql ],

            issue:       {
                name:            %q{Blind SQL Injection (differential analysis)},
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

This injection was detected as Arachni was able to inject specific SQL queries,
that if vulnerable, result in the responses for each injection being different.
This is known as a blind SQL injection vulnerability.
},
                references:  {
                    'OWASP'         => 'https://www.owasp.org/index.php/Blind_SQL_Injection',
                    'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html',
                    'WASC'          => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                    'W3 Schools'    => 'http://www.w3schools.com/sql/sql_injection.asp'
                },
                tags:            %w(sql blind differential injection database),
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
