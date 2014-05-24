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
# @version 0.2
#
# @see http://cwe.mitre.org/data/definitions/540.html
class Arachni::Checks::SourceCodeDisclosure < Arachni::Check::Base

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
                    (mutation.mutation_with_original_values? ||
                        mutation.mutation_with_sample_values?)

                # Don't bother if the current element type can't carry nulls.
                next if !mutation.valid_input_value_data?( "\0" )

                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.default_inputs[m.affected_input_name].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # If the extension of the default value is the same as of the
                # payload there's no need to add an extra mutation.
                next if ext == mutation.affected_input_value.split( '.' ).last

                # Null-terminate the injected value and append the ext.
                m.affected_input_value += "\0.#{ext}"

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

    def self.payloads
        return [] if !payload

        parsed_url    = uri_parse( payload )
        directories   = parsed_url.path.split( '/' )
        resource_name = directories.pop

        directories.reject!{ |d| d.empty? }

        ["/#{resource_name}"] + directories.reverse.inject([]) do |plds, directory|
            plds << "#{directory}/#{plds.last}"
        end.map { |pld| "/#{pld}#{resource_name}" }
    end

    def self.supported_extensions
        @supported_extensions ||=
            Set.new([ 'jsp', 'asp', 'aspx', 'php', 'htm', 'html' ])
    end

    def prepare
        # Let's look for fresh a payload -- i.e. an identifiable server-side resource.
        page.paths.each do |path|
            parsed_path = uri_parse( path )
            next if !self.class.supported_extensions.include?( parsed_path.resource_extension )

            self.class.payload = uri_parse( parsed_path.without_query ).path
            break
        end
    end

    def run
        return if self.class.payloads.empty?

        each_candidate_element do |element|
            element.taint_analysis( self.class.payloads, self.class.options )
        end
    end

    def self.info
        {
            name:        'Source code disclosure',
            description: %q{It tries to identify whether or not the web application
                can be forced to reveal source code.},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            platforms:   options[:regexp].keys,

            issue:       {
                name:            %q{Source code disclosure},
                description:     %q{The web application can be forced to reveal source code.},
                references:  {
                    'CWE' => 'http://cwe.mitre.org/data/definitions/540.html'
                },
                tags:            %w(code source file inclusion disclosure),
                cwe:             540,
                severity:        Severity::HIGH,
                remedy_guidance: %q{User inputs must be validated and filtered
                    before being included in a file-system path during file reading operations.},
            }

        }
    end

end
