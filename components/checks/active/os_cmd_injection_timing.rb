=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# OS command injection check using timing attacks.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
#
class Arachni::Checks::OSCmdInjectionTiming < Arachni::Check::Base

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
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },
            targets:     %w(Windows Unix),
            issue:       {
                name:            %q{Operating system command injection (timing attack)},
                description:     %q{The web application allows an attacker to
    execute arbitrary OS commands even though it does not return
    the command output in the HTML body.
    (This issue was discovered using a timing attack; timing attacks
    can result in false positives in cases where the server takes
    an abnormally long time to respond.
    Either case, these issues will require further investigation
    even if they are false positives.)},
                tags:            %w(os command code injection timing blind),
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
