=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

#
# Overloads the {String} class.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
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
        begin
            match = match( Regexp.new( Regexp.escape( string ) ) )
            match && !match.to_s.empty?
        rescue
            return nil
        end
    end

end
