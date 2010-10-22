=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

class String

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

end
