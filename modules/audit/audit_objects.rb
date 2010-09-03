=begin
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
# This module manipulates/audits/whatever
# HTML objects discovered by {Modules::Recon::ExtractObjects}.
#
# It serves as an example of how to pair discovery/data-mining modules<br/>
# with other modules.
#
# It will also show you how to use the module data storage system and <br/>
# how tell the system on which modules you depend on.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see Arachni::Modules::Recon::ExtractObjects
#
class AuditObjects < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        super( page )
    end

    def run( )
        
        # this is an example module,
        # there's no need for it during an audit
        return
        
        # you can get the objects you want by key
        objects = get_storage( 'objects' )

        if( objects.size == 0 )
            return
        end
        
        # or you can get the whole storage
#        storage =  get_store( )
                
        print_ok( 'Found an object:')
        print_ok( objects.to_s )
        
    end

    
    def self.info
        {
            'Name'           => 'AuditObjects',
            'Description'    => %q{Audits all object elements discovered by
                the ExtractObjects module.},
            'Elements'       => [],
            'Author'         => 'zapotek',
            'Version'        => '0.1',
            'References'     => {
                
            },
            'Targets'        => { 'Generic' => 'all' },
                
#            'Vulnerability'   => {
#                'Description' => %q{.},
#                'CWE'         => '',
#                'Severity'    => '',
#                'CVSSV2'       => '',
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
end
