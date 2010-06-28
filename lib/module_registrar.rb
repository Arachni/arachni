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
  # When inserted into modules it registers
  # them with Arachni::ModuleRegistry 
  #
  # @author: Zapotek <zapotek@segfault.gr> <br/>
  # @version: 0.1-planning
  #
  module ModuleRegistrar
  
    #
    # Callback invoked whenever Arachni::ModuleRegistrar
    # is included in another module or class.
    def ModuleRegistrar.included( mod )
  #    puts
  #    puts 'ModuleRegistrar'
  #    puts '----------------'
  #    puts mod.name
      Arachni::ModuleRegistry.register( mod )
    end
  
end
end