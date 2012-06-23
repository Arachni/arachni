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
# Simple OS command injection module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
#
class Arachni::Modules::OSCmdInjection < Arachni::Module::Base

    def self.opts
        @opts ||= {
            regexp: [
                /root:x:0:0:.+:[0-9a-zA-Z\/]+/,
                /\[boot loader\](.*)\[operating systems\]/
            ],
            format: [ Format::STRAIGHT, Format::APPEND ]
        }
    end

    def self.payloads
        @payloads ||= []
        if @payloads.empty?
            read_file( 'payloads.txt' ) do |str|
                [ '', '&&', '|', ';' ].each { |sep| @payloads << sep + " " + str }
                @payloads << "`" + " " + str + "`"
            end
        end
        @payloads
    end

    def run
        self.class.payloads.each { |str| audit( str, self.class.opts ) }
    end

    def self.info
        {
            name:        'OS command injection',
            description: %q{Tries to find operating system command injections.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.6',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },
            targets:     %w(Windows Unix),
            issue:       {
                name:            %q{Operating system command injection},
                description:     %q{The web application allows an attacker to
    execute arbitrary OS commands.},
                tags:            %w(os command code injection regexp),
                cwe:             '78',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{User inputs must be validated and filtered
    before being evaluated as OS level commands.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_exec'
            }
        }
    end

end
