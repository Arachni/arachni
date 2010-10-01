=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report
    
#
# Arachni::Report::Registrar module
#    
# When included into reports it registers
# them with Arachni::Report::Registry
#
# @author: Tasos "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see Arachni::Report::Registry
#
#
module Registrar
    
    #
    # Callback invoked whenever Arachni::Report::Registrar
    # is included in another module or class.<br/>
    # It registers the report with the system.
    # 
    def Registrar.included( report )
        Registry.register( report )
    end
    
end

end
end