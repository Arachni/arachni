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
# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class CodeInjectionTiming < Arachni::Module::Base

    include Arachni::Module::Utilities

    TIME = 10000 # ms

    def initialize( page )
        super( page )
    end

    def prepare( )

        @@__injection_str ||= []

        if @@__injection_str.empty?
            read_file( 'payloads.txt' ) {
                |str|

                [ ' ', ' && ', ';' ].each {
                    |sep|

                    # ok yes...this is crazy...not all of the targeted languages
                    # use miliseconds but we're working with timeouts so why not...
                    #
                    # I guess we'll just see what happens, heh... xD
                    #
                    @@__injection_str << sep + " " +
                        str.gsub( '__TIME__', ( TIME ).to_s )
                }

            }
        end

        @__opts = {
            :format  => [ Format::STRAIGHT ],
            :timeout => TIME + ( @http.average_res_time * 1000 ) - 5000,
        }

        @__logged = []
    end

    def run( )
        @found ||= false

        @@__injection_str.each {
            |str|
            audit( str, @__opts ) {
                |res, opts|

                next if @found

                # we have a timeout which probably means the attack succeeded
                if res.start_transfer_time == 0 && res.code == 0 && res.body.empty?
                    @found = true
                    log( opts, res )
                end
            }
        }
    end


    def self.info
        {
            :name           => 'Code injection (timing)',
            :description    => %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful using timing attacks.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
             },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Code injection (timing attack)},
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
