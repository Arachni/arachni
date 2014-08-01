=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Simple OS command injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
class Arachni::Checks::OSCmdInjection < Arachni::Check::Base

    def self.options
        @options ||= {
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
            unix:    [
                '/bin/cat /etc/passwd',
                '/bin/cat /etc/security/passwd'
            ],
            bsd: [
                '/bin/cat /etc/master.passwd',
            ],
            windows: [
                'type %SystemDrive%\\\\boot.ini',
                'type %SystemRoot%\\\\win.ini'
            ]
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
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Operating system command injection},
                description:     %q{The web application allows an attacker to
    execute arbitrary OS commands.},
                references:  {
                    'OWASP' => 'http://www.owasp.org/index.php/OS_Command_Injection'
                },
                tags:            %w(os command code injection regexp),
                cwe:             78,
                severity:        Severity::HIGH,
                remedy_guidance: %q{User inputs must be validated and filtered
    before being evaluated as OS level commands.}
            }
        }
    end

end
