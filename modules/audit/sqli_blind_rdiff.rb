=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Blind SQL injection audit module
#
# It uses reverse-diff analysis of HTML code in order to determine successful
# blind SQL injections.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class Arachni::Modules::BlindrDiffSQLInjection < Arachni::Module::Base

    def self.booleans
        @booleans ||= []
        if @booleans.empty?
            read_file( 'payloads.txt' ) do |str|
                [ '\'', '"', '' ].each { |quote| @booleans << str.gsub( '%q%', quote ) }
            end
        end
        @booleans
    end

    # options holding fault and boolean injection seeds
    def self.opts
        @opts ||= { faults: [ '\'"`' ], bools:  booleans }
    end

    def run
        audit_rdiff( self.class.opts )
    end

    def self.preferred
        %w(sqli)
    end

    def self.info
        {
            name:        'Blind (rDiff) SQL Injection',
            description: %q{It uses rDiff analysis to decide how different inputs affect
                the behavior of the the web pages.
                Using that as a basis it extrapolates about what inputs are vulnerable to blind SQL injection.
                (Note: This module may get confused by certain types of XSS vulnerabilities.
                    If this module returns a positive result you should investigate nonetheless.)},
            elements:    [ Element::LINK, Element::FORM, Element::COOKIE ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.3.2',
            references:  {
                'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            targets:     %w(Generic),

            issue:       {
                name:            %q{Blind SQL Injection},
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
