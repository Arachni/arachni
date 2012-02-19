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
# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class CodeInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare

        # digits from a sha1 hash
        # the codes in @__injection_strs will tell the web app
        # to sum them and echo the result
        @__rand1 = '287630581954'
        @__rand2 = '4196403186331128'

        @__opts = {
            :substring => ( @__rand1.to_i + @__rand2.to_i ).to_s,
            :format    => [ Format::APPEND, Format::STRAIGHT ]
        }

        # code to be injected to the webapp
        @__injection_strs = [
            "echo " + @__rand1 + "+" + @__rand2 + ";", # PHP
            "print " + @__rand1 + "+" + @__rand2 + ";", # Perl
            "print " + @__rand1 + " + " + @__rand2, # Python
            "Response.Write\x28" +  @__rand1  + '+' + @__rand2 + "\x29", # ASP
            "puts " + @__rand1 + " + " + @__rand2 # Ruby
        ]

        @__variations = [
            ';%s',
            "\";%s#",
            "';%s#"
        ]
    end

    def run

        # iterate through the injection codes
        @__injection_strs.each {
            |str|
            __variations( str ).each {
                |var|
                audit( var, @__opts )
            }
        }

    end

    def __variations( str )
        @__variations.map { |var| uri_encode( var % str, '+' ) } | [uri_encode( str, '+' )]
    end


    def self.info
        {
            :name           => 'Code injection',
            :description    => %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.5',
            :references     => {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
             },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Code injection},
                :description => %q{Arbitrary code can be injected into the web application
                    which is then executed as part of the system.},
                :tags        => [ 'code', 'injection', 'regexp' ],
                :cwe         => '94',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '7.5',
                :remedy_guidance    => %q{User inputs must be validated and filtered
                    before being evaluated as executable code.
                    Better yet, the web application should stop evaluating user
                    inputs as any part of dynamic code altogether.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_php_eval'
            }

        }
    end

end
end
end
