=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Blind SQL Injection check using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.3.3
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see https://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Checks::SqlInjectionTiming < Arachni::Check::Base

    prefer :sql_injection, :sql_injection_differential

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
            description: %q{Blind SQL Injection check using timing attacks.},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.3',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Blind SQL Injection (timing attack)},
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
that if vulnerable, result in the responses for each request being delayed before
being sent by the server.
This is known as a time-based blind SQL injection vulnerability.
},
                references:  {
                    'OWASP'         => 'https://www.owasp.org/index.php/Blind_SQL_Injection',
                    'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html',
                    'WASC'          => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                    'W3 Schools'    => 'http://www.w3schools.com/sql/sql_injection.asp'
                },
                tags:            %w(sql blind timing injection database),
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
