=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# OS command injection check using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see https://www.owasp.org/index.php/OS_Command_Injection
class Arachni::Checks::OsCmdInjectionTiming < Arachni::Check::Base

    prefer :os_cmd_injection

    def self.payloads
        @payloads ||= {
            unix:    'sleep __TIME__',
            windows: 'ping -n __TIME__ localhost'
        }.inject({}) do |h, (platform, payload)|
            h[platform] ||= []
            h[platform] << "#{payload}"

            ['', '\'', '"'].each do |q|
                h[platform] |= [ '&', '&&', '|', ';' ].
                    map { |sep| "#{q} #{sep} #{payload} #{sep} #{q}" }
            end

            h[platform] << "` #{payload}`"
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
            description: %q{
Tries to find operating system command injections using timing attacks.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.3.2',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Operating system command injection (timing attack)},
                description:     %q{
To perform specific actions from within a web application, it is occasionally
required to run Operating System commands and have the output of these commands
captured by the web application and returned to the client.

OS command injection occurs when user supplied input is inserted into one of these
commands without proper sanitisation and is then executed by the server.

Cyber-criminals will abuse this weakness to perform their own arbitrary commands
on the server. This can include everything from simple `ping` commands to map the
internal network, to obtaining full control of the server.

By injecting OS commands that take a specific amount of time to execute, Arachni
was able to detect time based OS command injection. This indicates that proper
input sanitisation is not occurring.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/OS_Command_Injection'
                },
                tags:            %w(os command code injection timing blind),
                cwe:             78,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a command to be
executed by the OS.

To validate data, the application should ensure that the supplied value contains
only the characters that are required to perform the required action.

For example, where the form field expects an IP address, only numbers and periods
should be accepted. Additionally, all control operators (`&`, `&&`, `|`, `||`,
`$`, `\`, `#`) should be explicitly denied and never accepted as valid input by
the server.
}
            }
        }
    end

end
