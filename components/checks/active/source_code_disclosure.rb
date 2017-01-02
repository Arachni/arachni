=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Identifies source code disclosures by injecting a known server-side file
# into all input vectors and then inspects the responses for the existence of
# source code.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/540.html
class Arachni::Checks::SourceCodeDisclosure < Arachni::Check::Base

    def self.options
        @options ||= {
            format:     [Format::STRAIGHT],
            signatures: SOURCE_CODE_SIGNATURES_PER_PLATFORM,

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                next if !mutation.affected_input_value

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
        candidate_paths  = page.paths
        candidate_paths |= page.jsons.map(&:action)
        candidate_paths |= page.xmls.map(&:action)

        # Let's look for fresh a payload -- i.e. an identifiable server-side resource.
        candidate_paths.each do |path|
            parsed_path = uri_parse( path )
            next if !self.class.supported_extensions.include?( parsed_path.resource_extension )

            self.class.payload = uri_parse( parsed_path.without_query ).path
            break
        end
    end

    def run
        return if self.class.payloads.empty?

        each_candidate_element do |element|
            element.signature_analysis( self.class.payloads, self.class.options )
        end
    end

    def self.info
        {
            name:        'Source code disclosure',
            description: %q{
It tries to identify whether or not the web application can be forced to reveal
source code.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.4',
            platforms:   options[:signatures].keys,

            issue:       {
                name:            %q{Source code disclosure},
                description:     %q{
A modern web application will be reliant on several different programming languages.

These languages can be broken up in two flavours. These are client-side languages
(such as those that run in the browser -- like JavaScript) and server-side
languages (which are executed by the server -- like ASP, PHP, JSP, etc.) to form
the dynamic pages (client-side code) that are then sent to the client.

Because all server side code should be executed by the server, it should never be
seen by the client. However in some scenarios, it is possible that:

1. The server side code has syntax errors and therefore is not executed by the
    server but is instead sent to the client.
2. Using crafted requests it is possible to force the server into displaying the
    source code of the application without executing it.

As the server-side source code often contains sensitive information, such as
database connection strings or details into the application workflow, this can be
extremely risky.

Cyber-criminals will attempt to discover pages that either accidentally or
forcefully allow the server-side source code to be disclosed, to assist in
discovering further vulnerabilities or sensitive information.

Arachni has detected server-side source code within the server's response.

_(False positives may occur when requesting binary files such as images
(.JPG or .PNG) and may require manual verification.)_
},
                references:  {
                    'CWE' => 'http://cwe.mitre.org/data/definitions/540.html'
                },
                tags:            %w(code source file inclusion disclosure),
                cwe:             540,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is important that input sanitisation be conducted to prevent application files
(ASP, JSP, PHP or config files) from being called. It is also important that the
file system permissions are correctly configured and that all unused files are
removed from the web root.

If these are not an option, then the vulnerable file should be removed from the server.
}
            }
        }
    end

end
