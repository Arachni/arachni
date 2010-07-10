=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

#
# Arachni::ModuleRegistrar module<br/>
# When included into modules it registers
# them with Arachni::ModuleRegistry
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
module ModuleRegistrar

    #
    # Callback invoked whenever Arachni::ModuleRegistrar
    # is included in another module or class.
    #
    def ModuleRegistrar.included( mod )
        Arachni::ModuleRegistry.register( mod )
    end
    
    #
    # Used by modules to register their results with the ModuleRegistry.
    #
    def register_results( results )
        Arachni::ModuleRegistry.register_results( results )
    end

end
end
