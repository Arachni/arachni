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

# File inclusion audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
# @see http://cwe.mitre.org/data/definitions/98.html
# @see https://www.owasp.org/index.php/PHP_File_Inclusion
class Arachni::Modules::FileInclusion < Arachni::Module::Base

    def self.options
        @options ||= {
            format: [Format::STRAIGHT],
            regexp: {
                unix: [
                    /DOCUMENT_ROOT.*HTTP_USER_AGENT/,
                    /(root|mail):.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/im
                ],
                windows: [
                    /\[boot loader\](.*)\[operating systems\]/im,
                    /\[fonts\](.*)\[extensions\]/im
                ],
                tomcat: [
                    /<web\-app/im
                ],

                # Generic PHP errors.
                php: [
                    /An error occurred in script/,
                    /Failed opening '.*?' for inclusion/,
                    /Failed opening required/,
                    /failed to open stream:.*/,
                    /<b>Warning<\/b>:\s+file/,
                    /<b>Warning<\/b>:\s+read_file/,
                    /<b>Warning<\/b>:\s+highlight_file/,
                    /<b>Warning<\/b>:\s+show_source/
                ],
                perl: [
                    /in .* at .* line d+?\./
                ]
            },

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.original[m.altered].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # Null-terminate the injected value and append the ext.
                m.altered_value += "\x00.#{ext}"

                # Pass our new element back to be audited.
                m
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
                '/boot.ini',
                '/windows/win.ini',
                '/winnt/win.ini'
            ].map { |p| [p, "c:#{p}", "#{p}#{'.'* 700}", p.gsub( '/', '\\' ) ] }.flatten,
            tomcat: [ '/WEB-INF/web.xml', '\WEB-INF\web.xml' ]
        }.inject({}) do |h, (platform, payloads)|
            h.merge platform => payloads.map { |p| [p, "file://#{p}" ] }.flatten
        end
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'File Inclusion',
            description: %q{It injects paths of common files (/etc/passwd and boot.ini)
                and evaluates the existence of a file inclusion vulnerability
                based on the presence of relevant content or errors in the HTTP responses.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.2',
            references:  {
                'OWASP' => 'https://www.owasp.org/index.php/PHP_File_Inclusion'
            },
            targets:     %w(Unix Windows Tomcat PHP Perl),

            issue:       {
                name:            %q{File Inclusion},
                description:     %q{Web applications occasionally use a 
                    parameters values to store the value of a file required by 
                    the server. An example of this is often seen in error pages 
                    where the actual file path for the error page is called the 
                    parameter value. For example 
                    'yoursite.com/error.php?page=404.php'. A file inclusion 
                    occurs when the parameter value (ie. path to file being 
                    called by the server) can be substituted with the path of 
                    another resource on the same server, and the server then 
                    displays that resource as text without processing it. 
                    Therefor revealing the server side source code. Cyber-
                    criminals will abuse this vulnerability to view restricted 
                    files or the source code of various files on the server. 
                    Arachni discovered that it was possible to substitute a 
                    parameter value with another resource and have the server 
                    return the contents of the resource to the client within 
                    the response. },
                tags:            %w(file inclusion error injection regexp),
                cwe:             '98',
                severity:        Severity::HIGH,
                remedy_guidance: %q{ It is recommended that untrusted or 
                    invalidated data is never used to form a literal file 
                    include request. To validate data, the application should 
                    ensure that the supplied value for a file is permitted. This 
                    can be achieved by performing whitelisting on the parameter 
                    value. The whitelist should contain a list of pages that the 
                    application is permitted to fetch resources from. If the 
                    supplied value does not match any value in the whitelist 
                    then the server should redirect to a standard error page. 
                    In some scenarios where dynamic content is being requested 
                    it may not be possible to perform validation of a list of 
                    trusted resources, therefor the list must also become 
                    dynamic (update as the files change), or perform filtering 
                    to remove any unrequired user input such as semicolons or 
                    periods etc. and only permit a-z0-9. It is also advised that 
                    sensitive file are not stored within the web root, and that 
                    the user permissions enforced by the directory are correct.}
            }

        }
    end

end
