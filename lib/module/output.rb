=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni
module Module


#
# Provides output functionality to the modules via the {Arachni::UI::Output}<br/>
# prepending the module name to the output message.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Output
  
    include Arachni::UI::Output
  
    alias :o_print_error    :print_error
    alias :o_print_status   :print_status
    alias :o_print_info     :print_info
    alias :o_print_ok       :print_ok
    alias :o_print_debug    :print_debug
    alias :o_print_verbose  :print_verbose
    alias :o_print_line     :print_line
  
    def print_error( str = '' )
        o_print_error( self.class.info[:name] + ": " + str )
    end
    
    def print_status( str = '' )
        o_print_status( self.class.info[:name] + ": " + str )
    end
    
    def print_info( str = '' )
        o_print_info( self.class.info[:name] + ": " + str )
    end
    
    def print_ok( str = '' )
        o_print_ok( self.class.info[:name] + ": " + str )
    end
    
    def print_debug( str = '' )
        o_print_debug( self.class.info[:name] + ": " + str )
    end

    def print_verbose( str = '' )
        o_print_verbose( self.class.info[:name] + ": " + str )
    end
    
    def print_line( str = '' )
        o_print_line( self.class.info[:name] + ": " + str )
    end

end

end
end
