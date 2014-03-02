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

# Blind SQL Injection module using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Modules::BlindTimingSQLInjection < Arachni::Module::Base

    prefer :sqli

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
            description: %q{Blind SQL Injection module using timing attacks
                (if the remote server suddenly becomes unresponsive or your network
                connection suddenly chokes up this module will probably produce false positives).},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3.2',
            references:  {
                'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html',
                'WASC'          => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                'W3 Schools'    => 'http://www.w3schools.com/sql/sql_injection.asp'
            },
            targets:     %w(MySQL PostgreSQL MSSQL),
            issue:       {
                name:            %q{Blind SQL Injection (timing attack)},
                description:     %q{Databases are used to store data. Due to the 
                    requirement for dynamic content of today's web applications, 
                    many web applications rely on a database backend to store 
                    data that will be called upon and processed by the web 
                    application (or other programs). Web applications retrieve 
                    data from the database by using a Structured Query Language 
                    (SQL) query. To meet demands of many developers, database 
                    servers (such as MSSQL, MySQL, Oracle etc.) have 
                    additionally built in functionality that can allow extensive 
                    control of the database and interaction with the host 
                    operating system itself. An SQL injection occurs when a 
                    value originating from the clients request is used within an 
                    SQL query without prior sanitisation. This could allow the 
                    cyber-criminal to steal the data stored in the database, or 
                    use the additional functionality of the database server to 
                    ake complete control of the server. When discovered, this 
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
                    injection was detected as Arachni was able to inject 
                    specific SQL queries containing 'waits' and/or 'benchmarks' 
                    that if vulnerable result in the responses for each request 
                    being delayed before being send by the server. For example 
                    if the injection payload told the database server to way for 
                    20 seconds, then the client will receive the response 20 
                    seconds after making the initial request. This is known as a 
                    time based blind SQL injection vulnerability.},
                tags:            %w(sql blind timing injection database),
                cwe:             '89',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{The only proven method to prevent against 
                    SQL injection attacks while still maintaining full 
                    application functionality is to use parametized queries 
                    (also known as prepared statements). When utilising this 
                    method of querying the database any value supplied by the 
                    client will be handled as a string value rather than part of 
                    the SQL query. Additionally, when utilising parametized 
                    queries, the database engine will automatically check to 
                    make sure the sting being used matches that of the column. 
                    For example the database engine will check the user supplied 
                    input is an integer if the database column is also an 
                    integer. Depending on the framework being used, 
                    implementation of parametized queries will differ. For 
                    framework specific examples see: 
                    'www.w3schools.com/sql/sql_injection.asp'. Other methods to 
                    help protect against SQL injection vulnerabilities exist 
                    however are not as effective and may either limit web 
                    application functionality, or remain vulnerable. For further 
                    information on these methods see: 
                    'www.owasp.org/index.php/SQL_Injection_Prevention_Cheat_Sheet'. 
                    Additional remediation activities such as configuring strict 
                    database permissions to limit queries that can be executed 
                    will further reduce the risk.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
