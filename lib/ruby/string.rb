=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Overloads the {String} class.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class String

    #
    # Gets the reverse diff between self and str on a word level.
    #
    #
    #   self = <<END
    #   This is the first test.
    #   Not really sure what else to put here...
    #   END
    #
    #   str = <<END
    #   This is the second test.
    #   Not really sure what else to put here...
    #   Boo-Yah!
    #   END
    #
    #   self.rdiff( str )
    #   # => "This is the test.\nNot really sure what else to put here...\n"
    #
    #
    # @param [String] str
    #
    # @return [String]
    #
    def rdiff( str )

        return self if self == str

        # get the words of the first text in an array
        words1 = self.split( /\b/ )

        # get the words of the second text in an array
        words2 = str.split( /\b/ )

        # get all the words that are different between the 2 arrays
        # math style!
        changes  = words1 - words2
        changes << words2 - words1
        changes.flatten!

        # get what hasn't changed (the rdiff, so to speak) as a string
        return ( words1 - changes ).join( '' )

    end

    def substring?( string )
        substring = self.downcase[string.downcase]
        return substring && !substring.empty?
    end

end
