=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Support

# Represents a signature, used to maintain a lightweight representation of a
# {String} and refine it using similar {String}s to remove noise.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Signature

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

    # @return [Signature]   Copy of `self`.
    def dup
        self.class.new( '' ).tap { |s| s.copy( tokens, @options ) }
    end

    def hash
        tokens.hash
    end

    # @note Takes into account the `:threshold` {#initialize option}.
    # @param [Signature]    other
    def ==( other )
        return true  if hash == other.hash
        return false if !@options[:threshold]

        ((other.tokens - tokens) - (tokens - other.tokens)).size < @options[:threshold]
    end

    protected

    def tokens
        @tokens
    end

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
        data.words(true).map { |token| (hash = token.hash).size > token.size ? token : hash }
    end

end
end
