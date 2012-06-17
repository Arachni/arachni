=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# @version 0.2.6
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class Arachni::Modules::PathTraversal < Arachni::Module::Base

    def self.traversals
        @trv ||=  [
            '../../../../../../../../../../../../../../../../',
            '//%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/' +
                '%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/' +
                '%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/'
        ]
    end

    def self.extensions
        @extentions ||= [
            "",
            "\0.htm",
            "\0.html",
            "\0.asp",
            "\0.aspx",
            "\0.php",
            "\0.txt",
            "\0.gif",
            "\0.jpg",
            "\0.jpeg",
            "\0.png",
            "\0.css"
        ]
    end

    def self.params
        @params ||= {
            'etc/passwd' => /root:x:0:0:.+:[0-9a-zA-Z\/]+/im,
            'boot.ini'   => /\[boot loader\](.*)\[operating systems\]/im
        }
    end

    def self.inputs
        @inputs ||= {}
        params.each do |file, regexp|
            extensions.each do |ext|
                traversals.each { |trv| @inputs[trv + file + ext] = regexp }
            end
        end if @inputs.empty?
        @inputs
    end

    def run
        self.class.inputs.each do |file, regexp|
            audit( file, format: [Format::STRAIGHT], regexp: regexp )
        end
    end

    def self.info
        {
            name:        'PathTraversal',
            description: %q{It injects paths of common files (/etc/passwd and boot.ini)
                and evaluates the existence of a path traversal vulnerability
                based on the presence of relevant content in the HTML responses.},
            elements:    [
                Element::FORM,
                Element::LINK,
                Element::COOKIE,
                Element::HEADER
            ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.6',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            targets:     { 'Generic' => 'all' },

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
