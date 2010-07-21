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

#
# Simple shell command injection module.
# It audits links, forms and cookies.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class SimpleCmdExec < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        @__cmd_id_regex   = /100434/ixm
        @__cmd_id         = '100434'
        @__injection_str  = '; expr 978 + 99456'
        
        @results = []
    end

    def run( )
        
        audit_links( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new(
                res.merge( { 'elem' => 'link' }.
                    merge( self.class.info )
                )
            )
        }

        audit_forms( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new(
                res.merge( { 'elem' => 'form' }.
                    merge( self.class.info )
                )
            )
        }

        audit_cookies( @__injection_str, @__cmd_id_regex, @__cmd_id ).each {
            |res|
            @results << Vulnerability.new(
                res.merge( { 'elem' => 'cookie' }.
                    merge( self.class.info )
                )
            )
        }
        
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'SimpleCmdExec',
            'Description'    => %q{Simple shell command execution recon module},
            'Methods'        => ['get', 'post', 'cookie'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                
            },
            'Targets'        => { 'PHP' => 'all' },
                
            'Vulnerability'   => {
                'Description' => %q{The web application allows an attacker to
                    execute OS commands.},
                'CWE'         => '78',
                'Severity'    => 'High',
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end

end
end
end
