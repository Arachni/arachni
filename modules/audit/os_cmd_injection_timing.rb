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

#
# OS command injection module using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.4
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
#
class Arachni::Modules::OSCmdInjectionTiming < Arachni::Module::Base

    prefer :os_cmd_injection

    def self.payloads
        @payloads ||= {
            unix:    'sleep __TIME__',
            windows: 'ping -n __TIME__ localhost'
        }.inject({}) do |h, (platform, payload)|
            h[platform] = [ '', '&', '&&', '|', ';' ].map { |sep| "#{sep} #{payload}" }
            h[platform] << "`#{payload}`"
            h
        end
    end

    def run
        audit_timeout self.class.payloads,
                       format:          [Format::STRAIGHT],
                       timeout:         4000,
                       timeout_divider: 1000,
                       add:             -1000
    end

    def self.info
        {
            name:        'OS command injection (timing)',
            description: %q{Tries to find operating system command injections using timing attacks.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.4',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection',
                'WASC'  => 'http://projects.webappsec.org/w/page/13246950/OS%20Commanding'
            },
            targets:     %w(Windows Unix),
            issue:       {
                name:            %q{Operating system command injection (timing attack)},
                description:     %q{To perform specific actions from within a 
                    web application, it is occasionally required to fun 
                    operating commands (Linux or Windows) and have the output of 
                    these commands captured by the web application and returned 
                    o the client. OS command injection occurs when user supplied 
                    input is inserted into one of these commands without proper 
                    sanitisation and executed by the server. Cyber criminals 
                    will abuse this weakness to perform their own arbitrary 
                    commands on the server. This can include everything from 
                    simple ping commands to map the internal network, to 
                    obtaining full control of the server. By injecting OS 
                    commands that take a specific amount of time to execute, 
                    Arachni was able to detect time based OS command injectino. 
                    This indicates that proper input sanitisation is not 
                    occurring.},
                tags:            %w(os command code injection timing blind),
                cwe:             '78',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{It is recommended that untrusted or 
                    invalidated data is never used to form a command to be 
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
