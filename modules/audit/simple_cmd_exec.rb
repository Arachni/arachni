=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# Simple shell command injection module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see http://cwe.mitre.org/data/definitions/78.html
# @see http://www.owasp.org/index.php/OS_Command_Injection    
#    
class SimpleCmdExec < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page )
        super( page )

        @__cmd_id_regex   = /100434/ixm
        @__cmd_id         = '100434'
        @__injection_str  = '; expr 978 + 99456'
        
        @results = []
    end

    def run( )
        
        audit_links( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new( res.merge( self.class.info ) )
        }

        audit_forms( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new( res.merge( self.class.info ) )
        }

        audit_cookies( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new( res.merge( self.class.info ) )
        }
        
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'SimpleCmdExec',
            'Description'    => %q{Simple shell command execution recon module},
            'Elements'       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                 'OWASP'         => 'http://www.owasp.org/index.php/OS_Command_Injection'
            },

            'Targets'        => { 'PHP' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{OS command injection},
                'Description' => %q{The web application allows an attacker to
                    execute OS commands.},
                'CWE'         => '78',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end

end
end
end
end
