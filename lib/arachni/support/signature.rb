=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::Support

# Represents a signature, used to maintain a lightweight representation of a
# {String} and refine it using similar {String}s to remove noise.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Signature

    attr_reader :tokens

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Seed data to use to initialize the signature.
    # @param    [Hash]    options
    # @option   options :threshold  [Float]
    #   Sets the maximum allowed {#difference} when performing
    #   {#similar? similarity} comparisons.
    def initialize( data, options = {} )
        @tokens  = tokenize( data )
        @options = options

        if @options[:threshold] && !@options[:threshold].is_a?( Numeric )
            fail ArgumentError, 'Option :threshold must be a number.'
        end
    end

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Data to use to refine the signature.
    #
    # @return   [Signature]
    #   `self`
    def refine!( data )
        @tokens &= tokenize( data )
        self
    end

    # @note The string will be tokenized based on whitespace.
    #
    # @param    [String, Signature]    data
    #   Data to use to refine the signature.
    #
    # @return   [Signature]
    #   New, refined signature.
    def refine( data )
        dup.refine!( data )
    end

    # @param    [Signature] other
    #
    # @return   [Float]
    #   Ratio of difference between signatures.
    def differences( other )
        return 1 if other.nil?
        return 0 if self == other

        ((tokens - other.tokens) | (other.tokens - tokens)).size /
            Float((other.tokens | tokens).size)
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

    # @return [Signature]
    #   Copy of `self`.
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
        compress data.split( /(?![\w])/ )
    end

    # Compresses the tokens by only storing unique #hash values.
    # Seems kinda silly but this can actually save us GB of RAM when comparing
    # large signatures, not to mention CPU cycles.
    def compress( tokens )
        tokens.uniq.map(&:hash)
    end

end
end
