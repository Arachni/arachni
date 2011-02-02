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
# Simple OS command injection module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection
#
class OSCmdInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare

        @__opts = {}
        @__opts[:regexp]   = [
            /\w+:.+:[0-9]+:[0-9]+:.+:[0-9a-zA-Z\/]+/i,
            /\[boot loader\](.*)\[operating systems\]/i
        ]
        @__opts[:format]   = [ Format::STRAIGHT ]

        @@__injection_str ||= []

        if @@__injection_str.empty?
            read_file( 'payloads.txt' ) {
                |str|

                [ '', '&&', '|', ';' ].each {
                    |sep|
                    @@__injection_str << sep + " " + str
                }

                @@__injection_str << "`" + " " + str + "`"
            }
        end

    end

    def run( )
        @@__injection_str.each {
            |str|
            audit( str, @__opts )
        }
    end


    def self.info
        {
            :name           => 'OS command injection',
            :description    => %q{Tries to find operating system command injections.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.3',
            :references     => {
                 'OWASP'         => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Operating system command injection},
                :description => %q{The web application allows an attacker to
                    execute arbitrary OS commands.},
                :tags        => [ 'os', 'command', 'code', 'injection', 'regexp' ],
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
