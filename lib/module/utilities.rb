=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# Utilities class
#
# Includes some useful methods for the system, the modules etc...
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Utilities
  
    #
    # Gets path from URL
    #
    # @param   [String]   url
    #
    # @return  [String]   path
    #
    def Utilities.get_path( url )
      
        splits = []
        tmp = ''
        
        url.each_char {
            |c|
            if( c != '/' )
                tmp += c
            else
                splits << tmp
                tmp = ''
            end
        }
        
        if( !tmp =~ /\./ )
          splits << tmp
        end
        
        return splits.join( "/" ) + '/'
    end
    
    #
    # Gets the reverse diff (strings that have not changed) between 2 strings
    #
    #
    # text1 = <<END
    # This is the first test.
    # Not really sure what else to put here...
    # END
    # 
    # text2 = <<END
    # This is the second test.
    # Not really sure what else to put here...
    # Boo-Yah!
    # END
    # 
    # Arachni::Modules::Utilities.rdiff( text1, text2 )
    #  # => "This is the  test.\nNot really sure what else to put here...\n"
    #
    #
    # @param  [String]  text1
    # @param  [String]  text2
    #
    # @return  [String]
    #
    def Utilities.rdiff( text1, text2 )
        
        return text1 if text1 == text2
        
        # get the words of the first text in an array
        words1 = text1.split( /\b/ )
    
        # get the words of the second text in an array
        words2 = text2.split( /\b/ )
    
        # get all the words that are different between the 2 arrays
        # math style!
        changes  = words1 - words2
        changes << words2 - words1
        changes.flatten!
    
        # get what hasn't changed (the rdiff, so to speak) as a string
        return ( words1 - changes ).join( '' ) 
    
    end
  
end  

end
end
