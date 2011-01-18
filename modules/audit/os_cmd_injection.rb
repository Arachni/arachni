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

    def initialize( page )
        super( page )

        @__opts = {}
        @__opts[:regexp]   = /c24dd6293d9d4b94f1fdc71bcbbb1d1f/ixm
        @__opts[:match]    = 'c24dd6293d9d4b94f1fdc71bcbbb1d1f'
        @__opts[:format]   = OPTIONS[:format] | [ Format::SEMICOLON ]

        # 'echo' is convinient since it exists on most popular operating systems
        @__injection_str   = 'echo c24dd6293d9d4b94f1fdc71bcbbb1d1f'

        @results = []
    end

    def run( )
        audit( @__injection_str, @__opts )
    end


    def self.info
        {
            :name           => 'OS command injection',
            :description    => %q{Tries to find operating system command injections.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.3',
            :references     => {
                 'OWASP'         => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Operating system command injection},
                :description => %q{The web application allows an attacker to
                    execute arbitrary OS commands.},
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
