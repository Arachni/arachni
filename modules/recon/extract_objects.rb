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
module Recon
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
# @version: 0.1
#
# @see Arachni::Modules::Audit::AuditObjects
#
#
class ExtractObjects < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page )
        # in this case we don't need to call the parent
        @page = page
    end

    def run( )

        # this is an example module,
        # there's no need for it during an audit
        return
        
        # get all objects from the HTML code 
        @__objects = @page.html.scan( /<object(.*?)<\/object>/ixm )

        #
        # add the object elements to storage
        #
        # you can use whatever key you want when saving data
        # but it's best to use the class name...keeps things tidy
        #
        add_storage( self.class.info[:name], @__objects )
    end

    
    def self.info
        {
            :name           => 'ExtractObjects',
            :description    => %q{Extracts all 'object' elements from a webpage.},
            :elements       => [],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
        }
    end
    
end
end
end
end
