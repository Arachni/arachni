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
# @version 0.4.1
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
            version:     '0.4.1',
            references:  {
                'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Blind SQL Injection (differential analysis)},
                description:     %q{SQL code can be injected into the web application
    even though it may not be obvious due to suppression of error messages.},
                tags:            %w(sql blind rdiff injection database),
                cwe:             '89',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{Suppression of error messages leads to
    security through obscurity which is not a good practise.
    The web application needs to enforce stronger validation
    on user inputs.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
