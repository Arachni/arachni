=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Support

# Represents a signature, used to keep a lightweight representation of a {String}
# and refine it with more similar {String}s to remove noise.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Signature

    # @note The string will be tokenized based on whitespace.
    # @param    [#to_s]    seed    Initial seed for the signature.
    def initialize( data )
        @tokens = data.to_s.tokens
    end

    # @note The string will be tokenized based on whitespace.
    # @param    [#to_s]    data    Data to use to refine the signature.
    # @return   [Signature] `self`
    def refine( data )
        @tokens &= data.to_s.tokens
        self
    end

    def hash
        @tokens.hash
    end

    def ==( other )
        hash == other.hash
    end

end
end
