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

# Identifies source code disclosures by injecting a known server-side file
# into all input vectors and then inspects the responses for the existence of
# source code.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
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
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            targets:     %w(PHP ASP JSP),
            references:  {
                'CWE' => 'http://cwe.mitre.org/data/definitions/540.html'
            },
            issue:       {
                name:            %q{Source code disclosure},
                description:     %q{A modern web application will be reliant on 
                    several different programming languages. These languages can 
                    be broken up into two flavours. These are client side 
                    languages such as those that run in the browser eg. 
                    JavaScript and HTML, and server side languages that are 
                    executed by the server (ASP, PHP, JSP, etc) to form the 
                    dynamic pages (client side code) that are then sent to the 
                    client. Because all server side code should be executed by 
                    the server, it should never be seen by the client. However 
                    in some scenarios, it is possible that 1. The server side 
                    code has syntax error and therefor is not executed to by the 
                    server and is instead sent to the client, or 2. Using 
                    crafted requests it is possible to force the server into 
                    displaying the source code of the application without 
                    executing it. As the server side source code often contains 
                    sensitive information such as database connection strings or 
                    details into the application workflow this can be extremely 
                    risky. Cyber-criminals will attempt to discover pages that 
                    either accidently or forcefully allow the server side source 
                    code to be disclosed, to assist in discovering further 
                    vulnerabilities or sensitive information. Arachni has 
                    detected server side source code within the server's 
                    response. Note: false positives may occur when requesting 
                    image files such as .JPG or .PNG and may require manual 
                    verification.},
                tags:            %w(code source file inclusion disclosure),
                cwe:             '540',
                severity:        Severity::HIGH,
                remedy_guidance: %q{If confirmation reveals the leakage of 
                    server side source code, then the following remediation 
                    actions should be applied. Determine the context in which 
                    the source code is disclosed. ie. Caused through coding 
                    errors, or abusing existing functionality. If due to errors 
                    in the server side code, then the code causing the 
                    disclosure should be rewritten. If it is through the abuse 
                    of existing functionality then it is important that, input 
                    sanitisation be conducted to prevent application files (ASP, 
                    JSP, PHP or config files) cannot be called. It is also 
                    important that the file system permissions are correctly 
                    configured, and that all unused files are removed from the 
                    web root. If these are not an option, then the vulnerable 
                    file should be removed from the server.},
            }

        }
    end

end
