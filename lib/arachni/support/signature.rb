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
