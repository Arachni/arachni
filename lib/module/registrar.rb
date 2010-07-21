=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# Arachni::Module::Registrar module<br/>
# When included into modules it registers
# them with Arachni::Module::Registry
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-pre
#
module Registrar

    #
    # Callback invoked whenever Arachni::Module::Registrar
    # is included in another module or class.
    #
    def Registrar.included( mod )
        Registry.register( mod )
    end
    
    #
    # Used by modules to register their results with the Registry.
    #
    # @param    [Array<Vulnerability>]    results    module results
    #
    def register_results( results )
        Registry.register_results( results )
    end
    
    #
    # Used by modules to store persistent data they want to share
    #
    # @param    [Object]  key     the key under which to store the value data
    # @param    [Object]  value   the value of the key
    #
    def add_storage( key, value )
        Registry.add_storage( { key => value } )
    end
    
    #
    # Used by modules to get persistent data from storage
    #
    # @param    [Object]  key     get the data under that key
    #
    # @return    [Object]    the data under key
    #
    def get_storage( key )
        Registry.get_storage( key )
    end
    
    #
    # Gets the entire storage array
    #
    # @return    [Array<Hash>]
    #
    def get_store( )
        Registry.get_store( )
    end

end
end
end
