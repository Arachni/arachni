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

module Arachni::Support

# Represents a signature, used to maintain a lightweight representation of a
# {String} and refine it using similar {String}s to remove noise.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Signature

    attr_reader :tokens

    # @note The string will be tokenized based on whitespace.
    # @param    [String, Signature]    data
    #   Seed data to use to initialize the signature.
    # @param    [Hash]    options
    # @option   options :threshold  [Integer]
    #   Sets the maximum allowed difference (in tokens) when performing
    #   {#== comparisons}.
    def initialize( data, options = {} )
        @tokens  = tokenize( data )
        @options = options

        if @options[:threshold] && !@options[:threshold].is_a?( Numeric )
            fail ArgumentError, 'Option :threshold must be a number.'
        end
    end

    # @note The string will be tokenized based on whitespace.
    # @param    [String, Signature]    data    Data to use to refine the signature.
    # @return   [Signature] `self`
    def refine!( data )
        @tokens &= tokenize( data )
        self
    end

    # @note The string will be tokenized based on whitespace.
    # @param    [String, Signature]    data    Data to use to refine the signature.
    # @return   [Signature] New, refined signature.
    def refine( data )
        dup.refine!( data )
    end

    # @note **Very** expensive, use {#differences} when possible.
    #
    # @param    [Signature] other
    # @param    [Integer]   ins Cost of an `insert` operation.
    # @param    [Integer]   del Cost of a `delete` operation.
    # @param    [Integer]   sub Cost of a `substitute` operation.
    #
    # @return   [Integer]   Levenshtein distance
    #
    # @see http://www.informit.com/articles/article.aspx?p=683059&seqNum=36
    def distance( other, ins = 2, del = 2, sub = 1 )
        return nil if other.nil?
        return 0   if hash == other.hash

        # Distance matrix.
        dm = []

        # Initialize first row values.
        dm[0] = (0..tokens.size).collect { |i| i * ins }
        fill  = [0] * (tokens.size - 1)

        # Initialize first column values.
        (1..other.tokens.size).each do |i|
            dm[i] = [i * del, fill.flatten]
        end

        # Populate matrix.
        (1..other.tokens.size).each do |i|
            (1..tokens.size).each do |j|
                # Critical comparison.
                dm[i][j] = [
                    dm[i-1][j-1] + (tokens[j-1] == other.tokens[i-1] ? 0 : sub),
                    dm[i][j-1] + ins,
                    dm[i-1][j] + del
                ].min
            end
        end

        # The last value in matrix is the Levenshtein distance.
        dm.last.last
    end

    # @param    [Signature] other
    # @return   [Integer]   Amount of differences between signatures.
    def differences( other )
        return nil if other.nil?
        return 0   if self == other

        ((tokens - other.tokens) | (other.tokens - tokens)).size
    end

    # @param    [Signature] other
    # @param    [Integer] threshold
    #   Threshold of {#differences differences}.
    #
    # @return   [Bool]
    def similar?( other, threshold = @options[:threshold] )
        fail 'No threshold given.' if !threshold
        self == other || differences( other ) < threshold
    end

    # @return [Signature]   Copy of `self`.
    def dup
        self.class.new( '' ).tap { |s| s.copy( tokens, @options ) }
    end

    def hash
        tokens.hash
    end

    # @param [Signature]    other
    def ==( other )
        hash == other.hash
    end

    protected

    def copy( tokens, options )
        @tokens  = tokens.dup
        @options = options.dup
    end

    private

    # @param    [Signature, String] data
    #
    # @return [Array<String,Integer>]
    #   Words as tokens represented by either the words themselves or their
    #   hashes, depending on which is smaller in size.
    def tokenize( data )
        return data.tokens if data.is_a? self.class
        data.split /(?![\w])/
    end

end
end
