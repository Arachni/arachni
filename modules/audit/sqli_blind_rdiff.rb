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

# Blind SQL injection audit module
#
# It uses reverse-diff analysis of HTML code in order to determine successful
# blind SQL injections.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.4.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Modules::BlindrDiffSQLInjection < Arachni::Module::Base

    prefer :sqli

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
        falses = queries_for_expression( '1=%q%2' )

        queries_for_expression( '1=%q%1' ).each.with_index do |true_expr, i|
            pairs << { true_expr => falses[i] }
        end

        @options = { false: '-1', pairs: pairs }
    end

    def run
        audit_rdiff self.class.options
    end

    def self.info
        {
            name:        'Blind SQL Injection (differential analysis)',
            description: %q{It uses differential analysis to determine how different inputs affect
                the behavior of the web application and checks if the displayed behavior is consistent
                with that of a vulnerable application.},
            elements:    [ Element::LINK, Element::FORM, Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.4.2',
            references:  {
                'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html',
                'WASC'          => 'http://projects.webappsec.org/w/page/13246963/SQL%20Injection',
                'W3 Schools'    => 'http://www.w3schools.com/sql/sql_injection.asp'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Blind SQL Injection (differential analysis)},
                description:     %q{Databases are used to store data. Due to the 
                    requirement for dynamic content of today's web applications, 
                    many web applications rely on a database backend to store 
                    data that will be called upon and processed by the web 
                    application (or other programs). Web applications retrieve 
                    data from the database by using a Structured Query Language 
                    (SQL) query. To meet demands of many developers, database 
                    servers (such as MSSQL, MySQL, Oracle etc.) have additionally 
                    built in functionality that can allow extensive control of 
                    the database and interaction with the host operating system 
                    itself. An SQL injection occurs when a value originating 
                    from the clients request is used within an SQL query without 
                    prior sanitisation. This could allow the cyber-criminal to 
                    steal the data stored in the database, or use the additional 
                    functionality of the database server to take complete 
                    control of the server. When discovered, this allows cyber-
                    criminals the ability to inject their own SQL query 
                    (injected query will normally be placed within the existing 
                    application query) and have it executed by the database 
                    server. The successful exploitation of a SQL injection can 
                    be a devastating to an organisation, and is one of the most 
                    commonly exploited web application vulnerabilities. To 
                    discover a SQL injection, Arachni injects multiple different 
                    payloads into specific locations within the client request. 
                    Arachni discovered that the affected page and parameter may 
                    be vulnerable. This injection was detected as Arachni was 
                    able to inject specific SQL queries that if vulnerable 
                    result in the responses for each injection being different. 
                    This is known as a blind SQL injection vulnerability.},
                tags:            %w(sql blind rdiff injection database),
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
                    framework specific examples see: 'www.w3schools.com/sql/sql_injection.asp'. 
                    Other methods to help protect against SQL injection 
                    vulnerabilities exist however are not as effective and may 
                    either limit web application functionality, or remain 
                    vulnerable. For further information on these methods see: 
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
