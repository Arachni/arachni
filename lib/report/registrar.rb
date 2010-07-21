=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report
    

module Registrar
    
    #
    # Callback invoked whenever Arachni::Report::Registrar
    # is included in another module or class.
    #
    def Registrar.included( report )
        Registry.register( report )
    end
    
end

end
end