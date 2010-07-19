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
# Arachni::Exceptions module<br/>
# It holds the framework's exceptions.
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
module Exceptions

    def initialize( msg )
        super( msg )
    end

    
    class NoAuditOpts < StandardError
        include Exceptions
        
    end

    class NoMods < StandardError
        include Exceptions
        
    end

    class ModNotFound < StandardError
        include Exceptions
        
    end
        
    class NoURL < StandardError
        include Exceptions
            
    end

    class InvalidURL < StandardError
        include Exceptions
            
    end    
    
    class NoCookieJar < StandardError
        include Exceptions
            
    end    
    
end

end