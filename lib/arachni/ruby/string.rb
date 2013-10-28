=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'zlib'

#
# Overloads the {String} class.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class String

    #
    # Gets the reverse diff between self and str on a word level.
    #
    #
    #     str = <<END
    #     This is the first test.
    #     Not really sure what else to put here...
    #     END
    #
    #     str2 = <<END
    #     This is the second test.
    #     Not really sure what else to put here...
    #     Boo-Yah!
    #     END
    #
    #     str.rdiff( str2 )
    #     # => "This is the test.\nNot really sure what else to put here...\n"
    #
    #
    # @param [String] other
    #
    # @return [String]
    #
    def rdiff( other )
        return self if self == other

        # get the words of the first text in an array
        s_words = words

        # get what hasn't changed (the rdiff, so to speak) as a string
        (s_words - (s_words - other.words)).join
    end

    #
    # Calculates the difference ratio (at a word level) between `self` and `other`
    #
    # @param    [String]    other
    #
    # @return   [Float]     `0.0` (identical strings) to `1.0` (completely different)
    #
    def diff_ratio( other )
        return 0.0 if self == other
        return 1.0 if empty? || other.empty?

        s_words = self.words( true )
        o_words = other.words( true )

        common = (s_words & o_words).size.to_f
        union  = (s_words | o_words).size.to_f

        (union - common) / union
    end

    #
    # Returns the words in `self`.
    #
    # @param    [Bool]  strict  include *only* words, no boundary characters (like spaces, etc.)
    #
    # @return   [Array<String>]
    #
    def words( strict = false )
        splits = split( /\b/ )
        splits.reject! { |w| !(w =~ /\w/) } if strict
        splits
    end

    # @return [Array<Integer>]  Words as integer tokens.
    def tokens
        words( true ).map(&:hash)
    end

    # @return [String] Shortest word.
    def shortest_word
        words( true ).sort_by { |w| w.size }.first
    end

    # @return [String] Longest word.
    def longest_word
        words( true ).sort_by { |w| w.size }.last
    end

    # @return   [Integer]
    #   In integer with the property of:
    #
    #   If `str1 == str2` then `str1.persistent_hash == str2.persistent_hash`.
    #
    #   It basically has the same function as Ruby's `#hash` method, but does
    #   not use a random seed per Ruby process -- making it suitable for use
    #   in distributed systems.
    #
    def persistent_hash
        Zlib.crc32 self
    end

    def substring?( string )
        begin
            cmatch = match( Regexp.new( Regexp.escape( string ) ) )
            cmatch && !cmatch.to_s.empty?
        rescue
            nil
        end
    end

    def repack
        unpack( 'C*' ).pack( 'U*' )
    end

    def recode!
        force_encoding( 'utf-8' )
        encode!( 'utf-16be', invalid: :replace, undef: :replace ).encode( 'utf-8' )
    end

    def recode
        dup.recode!
    end


    def binary?
        # Stolen from YAML.
        encoding == Encoding::ASCII_8BIT ||
            index("\x00") ||
            count("\x00-\x7F", "^ -~\t\r\n").fdiv(length) > 0.3
    end

end
