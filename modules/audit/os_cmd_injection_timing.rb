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
# OS command injection module using timing attacks.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
#
class OSCmdInjectionTiming < Arachni::Module::Base

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

                [ '', '&&', '|', ';' ].each {
                    |sep|
                    @@__injection_str << sep + " " +
                        str.gsub( '__TIME__', ( TIME / 1000 ).to_s )
                }

                @@__injection_str << "`" + str.gsub( '__TIME__', ( TIME / 1000 ).to_s ) + "`"
            }
        end

        @__opts = {
            :format  => [ Format::STRAIGHT ],
            :timeout => TIME + ( @http.average_res_time * 1000 ) - 3000,
        }

    end

    def run( )
        @@__injection_str.each {
            |str|
            audit( str, @__opts ) {
                |res, opts|

                # we have a timeout which probably means the attack succeeded
                if res.start_transfer_time == 0 && res.code == 0 && res.body.empty?
                    log( opts, res )
                end
            }
        }
    end

    def self.info
        {
            :name           => 'OS command injection (timing)',
            :description    => %q{Tries to find operating system command injections using timing attacks.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                 'OWASP'         => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Operating system command injection},
                :description => %q{The web application allows an attacker to
                    execute arbitrary OS commands even though it does not return
                    the command output in the HTML body.},
                :cwe         => '78',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => %q{User inputs must be validated and filtered
                    before being evaluated as OS level commands.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_exec'
            }

        }
    end

end
end
end
