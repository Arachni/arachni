=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Identifies source code disclosures by injecting a known server-side file
# into all input vectors and then inspects the responses for the existence of
# source code.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
#
# @see http://cwe.mitre.org/data/definitions/540.html
class Arachni::Modules::SourceCodeDisclosure < Arachni::Module::Base

    def self.options
        @options ||= {
            format:  [Format::STRAIGHT],
            regexp:  {
                php: [
                    /<\?php/
                ],
                jsp: [
                    /<%|<%=|<%@\s+page|<%@\s+include|<%--|import\s+javax.servlet|
                        import\s+java.io|import=['"]java.io|request\.getParameterValues\(|
                        response\.setHeader|response\.setIntHeader\(/m
                ],
                asp: [
                    /<%|Response\.Write|Request\.Form|Request\.QueryString|
                        Response\.Flush|Session\.SessionID|Session\.Timeout|
                        Server\.CreateObject|Server\.MapPath/im
                ]
            },

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                next if mutation.is_a?( Arachni::Form ) &&
                    (mutation.original? || mutation.sample?)

                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.original[m.altered].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # If the extension of the default value is the same as of the
                # payload there's no need to add an extra mutation.
                next if ext == mutation.altered_value.split( '.' ).last

                # Null-terminate the injected value and append the ext.
                m.altered_value += "\x00.#{ext}"

                # Pass our new element back to be audited.
                m
            end
        }
    end

    def self.payload=( file )
        @payload = file
    end

    def self.payload
        @payload
    end

    def self.supported_extensions
        @supported_extensions ||=
            Set.new([ 'jsp', 'asp', 'aspx', 'php', 'htm', 'html' ])
    end

    def prepare
        # Let's look for fresh a payload -- i.e. an identifiable server-side page.
        page.paths.each do |path|
            parsed_path = uri_parse( path )
            next if !self.class.supported_extensions.include?( parsed_path.resource_extension )

            self.class.payload = uri_parse( parsed_path.without_query ).path
            break
        end
    end

    def run
        return if !self.class.payload

        candidate_elements.each do |element|
            payload = calculate_path_to_payload_from( element.action )
            next if !payload

            element.taint_analysis( payload, self.class.options )
        end
    end

    def calculate_path_to_payload_from( url )
        return if !(up_to_path = uri_parse( url ).up_to_path)

        Pathname.new( self.class.payload ).
            relative_path_from( Pathname.new( uri_parse( up_to_path ).path ) ).to_s
    end

    def self.info
        {
            name:        'Source code disclosure',
            description: %q{It tries to identify whether or not the web application
                can be forced to reveal source code.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            targets:     %w(PHP ASP JSP),
            references:  {
                'CWE' => 'http://cwe.mitre.org/data/definitions/540.html'
            },
            issue:       {
                name:            %q{Source code disclosure},
                description:     %q{The web application can be forced to reveal source code.},
                tags:            %w(code source file inclusion disclosure),
                cwe:             '540',
                severity:        Severity::HIGH,
                remedy_guidance: %q{User inputs must be validated and filtered
                    before being included in a file-system path during file reading operations.},
            }

        }
    end

end
