=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module RPC
module XML
module Server


#
# Utilities class
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Utilities

    #
    # Recursively removes nils.
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
    def unnil( hash )
        hash.each_pair {
            |k, v|
            hash[k] = '' if v.nil?
            hash[k] = unnil( v ) if v.is_a? Hash
        }

        return hash
    end


end

end
end
end
end