=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Overloads the {Object} class providing a deep_clone() method
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Object

    #
    # Deep-clones self using a Marshal dump-load.
    #
    def deep_clone
        begin
            return Marshal.load( Marshal.dump( self  ) )
        rescue Exception
            return self
        end
    end

end
