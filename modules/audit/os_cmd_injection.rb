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

# Simple OS command injection module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
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
            version:     '0.2.2',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection',
                'WASC'  => 'http://projects.webappsec.org/w/page/13246950/OS%20Commanding'
            },
            targets:     %w(Windows Unix),
            issue:       {
                name:            %q{Operating system command injection},
                description:     %q{To perform specific actions from within a 
                    web application, it is occasionally required to run
                    Operating System commands (Linux or Windows) and have the output of
                    these commands captured by the web application and returned 
                    to the client. OS command injection occurs when user supplied
                    input is inserted into one of these commands without proper 
                    sanitisation and executed by the server. Cyber criminals 
                    will abuse this weakness to perform their own arbitrary 
                    commands on the server. This can include everything from 
                    simple ping commands to map the internal network, to 
                    obtaining full control of the server. Arachni was able to 
                    inject specific Operating System commands and have the output from
                    that command contained within the server response. This 
                    indicates that proper input sanitisation is not occurring.},
                tags:            %w(os command code injection regexp),
                cwe:             '78',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{It is recommended that untrusted or 
                    non-validated data is never used to form a command to be
                    executed on the server. To validate data, the application 
                    should ensure that the supplied value contains only the 
                    characters that are required to perform the required action. 
                    For example, where the form field expects an IP address, 
                    only numbers and full stops should be accepted. Additionally 
                    all control operators (&, &&, |, ||, $, \, #) should be 
                    explicitly denied, and never accepted by as input by the 
                    server.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_exec'
            }
        }
    end

end
