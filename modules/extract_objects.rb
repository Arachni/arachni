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
# This is a discovery/data mining example module.
#
# It extracts all object elements from a webpage<br/>
# and adds them to module storage to be used by other modules later on.
#
# It will also show you how to use the module data storage system.
#
# Such modules can be used for general data mining or discovery<br/>
# and then pass their data to the system to be used by other modules.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see AuditObjects
#
#
class ExtractObjects < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        # in this case we don't need to call the parent
        
        # get all objects from the HTML code 
        @__objects = page_data['html'].scan( /<object(.*?)<\/object>/ixm )
    end

    def run( )
        # add the object elements to storage
        add_storage( 'objects', @__objects )
    end

    
    def self.info
        {
            'Name'           => 'ExtractObjects',
            'Description'    => %q{Extracts all 'object' elements from a webpage.},
            'Methods'        => ['get'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                
            },
            'Targets'        => { 'Generic' => 'all' },
        }
    end
    

end
end
end
