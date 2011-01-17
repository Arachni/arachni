=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# eval() audit module.
#
# It audits links, forms and cookies for code injection.
#
# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class Eval < Arachni::Module::Base

    def initialize( page )
        super( page )

        # code to inject
        @__injection_strs = []

        # digits from a sha1 hash
        # the codes in @__injection_strs will tell the web app
        # to sum them and echo the result
        @__rand1 = '287630581954'
        @__rand2 = '4196403186331128'

        # our results array
        @results = []
    end

    def prepare( )

        @__opts = {}

        # the sum of the 2 numbers as a string
        @__opts[:match]   =  ( @__rand1.to_i + @__rand2.to_i ).to_s
        @__opts[:regexp]  = Regexp.new( @__opts[:match] )
        @__opts[:format]  = [ Format::APPEND ]

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

    def run( )

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
        @__variations.map{ |var| var % str } | [str]
    end


    def self.info
        {
            :name           => 'Eval',
            :description    => %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.3',
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
