=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

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
class SimpleCmdExec < Arachni::Module

    include Arachni::ModuleRegistrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        @__cmd_id_regex   = /100434/ixm
        @__cmd_id         = '100434'
        @__injection_str  = '; expr 978 + 99456'
        
        @results = Hash.new
    end

    def run( )
        
        @results['links'] =
            audit_links( @__injection_str, @__cmd_id_regex, @__cmd_id )

        @results['forms'] =
            audit_forms( @__injection_str, @__cmd_id_regex, @__cmd_id )

        @results['cookies'] =
            audit_cookies( @__injection_str, @__cmd_id_regex, @__cmd_id )
        
        register_results( { 'SimpleCmdExec' => @results } )
    end

    
    def self.info
        {
            'Name'           => 'SimpleCmdExec',
            'Description'    => %q{Simple shell command execution recon module},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     =>
                [
                ],
            'Targets'        => { 'PHP' => 'all' }
        }
    end

end
end
end
