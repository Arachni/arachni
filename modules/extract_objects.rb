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
# This is a discovery/data mining example module.
#
# It extracts all object elements from a webpage
# and adds them to module storage to be used by other modules later on.
#
# It will also show you how to use the module's storage system.
#
# Such modules can be used for general data mining or discovery
# and then pass their data to the system to be used by other modules.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev: 127 $
#
# @see AuditObjects AuditObjects module
#
#
class ExtractObjects < Arachni::Module

    include Arachni::ModuleRegistrar
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
            'Version'        => '$Rev: 127 $',
            'References'     => {
                
            },
            'Targets'        => { 'Generic' => 'all' },
        }
    end
    

end
end
end
