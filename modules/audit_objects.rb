=begin
  $Id: simple_cmd_exec.rb 127 2010-07-18 02:17:45Z zapotek $

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

module Modules

#
# This module manipulates/audits/whatever
# HTML objects discovered by ExtractObjects
#
# It serves as an example of how to pair discovery/data-mining modules
# with other modules.
#
# It will also show you how to use the module's storage system.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev: 127 $
#
# @see ExtractObjects ExtractObjects module
#
class AuditObjects < Arachni::Module

    include Arachni::ModuleRegistrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )
    end

    def run( )
        
        # you can get the objects you want by key
        objects = get_storage( 'objects' )

        # or you can get the whole storage
#        storage =  get_store( )
                
        print_ok( self.class.info['Name'] + ' found an object:')
        print_ok( objects.to_s )
        
    end

    
    def self.info
        {
            'Name'           => 'AuditObjects',
            'Description'    => %q{Audits all object elements discovered by
                the ExtractObjects module.},
            'Methods'        => ['get'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 127 $',
            'References'     => {
                
            },
            'Targets'        => { 'Generic' => 'all' },
                
#            'Vulnerability'   => {
#                'Description' => %q{The web application allows an attacker to
#                    execute OS commands.},
#                'CWE'         => '78',
#                'Severity'    => 'High',
#                'CVSSV2'       => '9.0',
#                'Remedy_Guidance'    => '',
#                'Remedy_Code' => '',
#            }

        }
    end
    
    #
    # Let the framework know our dependencies
    #
    def self.deps
        # we depend on the 'extract_objects' module 
        ['extract_objects']
    end

end
end
end
