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

# SQL Injection audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://unixwiz.net/techtips/sql-injection.html
# @see http://en.wikipedia.org/wiki/SQL_injection
# @see http://www.securiteam.com/securityreviews/5DP0N1P76E.html
# @see http://www.owasp.org/index.php/SQL_Injection
class Arachni::Modules::SQLInjection < Arachni::Module::Base

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
            description: %q{SQL injection module, uses known SQL DB errors to identify vulnerabilities.},
            elements:    [Element::LINK, Element::FORM, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.2',
            references:  {
                'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                'OWASP'      => 'http://www.owasp.org/index.php/SQL_Injection',
                'WASC'       => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                'W3 Schools' => 'http://www.w3schools.com/sql/sql_injection.asp'
            },
            targets:     %w(Oracle ColdFusion InterBase PostgreSQL MySQL MSSQL EMC
                            SQLite DB2 Informix Firebird MaxDB Sybase Frontbase Ingres HSQLDB),
            issue:       {
                name:            %q{SQL Injection},
                description:     %q{Databases are used to store data. Due to the 
                    requirement for dynamic content of today's web applications, 
                    many web applications rely on a database backend to store 
                    data that will be called upon and processed by the web 
                    application (or other programs). Web applications retrieve 
                    data from the database by using a Structured Query Language 
                    (SQL) query. To meet demands of many developers, database 
                    servers (such as MSSQL, MySQL, Oracle etc.) have 
                    additional built-in functionality that can allow extensive
                    control of the database and interaction with the host 
                    operating system itself. An SQL injection occurs when a 
                    value originating from the client's request is used within an
                    SQL query without prior sanitisation. This could allow the 
                    cyber-criminal to steal the data stored in the database, or 
                    use the additional functionality of the database server to 
                    take complete control of the server. When discovered, this 
                    allows cyber-criminals the ability to inject their own SQL 
                    query (injected query will normally be placed within the 
                    existing application query) and have it executed by the 
                    database server. The successful exploitation of a SQL 
                    injection can be a devastating to an organisation, and is 
                    one of the most commonly exploited web application 
                    vulnerabilities. To discover a SQL injection, Arachni 
                    injects multiple different payloads into specific locations 
                    within the client request. Arachni discovered that the 
                    affected page and parameter may be vulnerable. This 
                    injection was detected as Arachni was able to cause the 
                    server to respond to the request with a database related 
                    error. This is the easiest form of detection, and is known 
                    as error based SQL injection vulnerability.},
                tags:            %w(sql injection regexp database error),
                cwe:             '89',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{The only proven method to prevent against 
                    SQL injection attacks while still maintaining full 
                    application functionality is to use parameterized queries
                    (also known as prepared statements). When utilising this 
                    method of querying the database any value supplied by the
                    client will be handled as a string value rather than part of 
                    the SQL query. Additionally, when utilising parameterized
                    queries, the database engine will automatically check to 
                    make sure the string being used matches that of the column.
                    For example the database engine will check the user supplied 
                    input is an integer if the database column is also an 
                    integer. Depending on the framework being used, 
                    implementation of parameterized queries will differ.
                    Other methods to help protect against SQL injection 
                    vulnerabilities exist however are not as effective and may
                    either limit web application functionality, or remain 
                    vulnerable.
                    Additional remediation activities such as configuring strict 
                    database permissions to limit queries that can be executed, 
                    and configuring the webserver to display custom error 
                    messages to prevent error based detection will both further 
                    reduce the risk.},
                metasploitable:  'auxiliary/arachni_sqlmap'
            }
        }
    end

end
