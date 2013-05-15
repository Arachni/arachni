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

require 'set'

module Arachni
module Support::LookUp

#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base

    DEFAULT_OPTIONS = {
        hasher: :hash
    }

    # @param    [Hash]  options
    # @option   options [Symbol]    (:hasher)
    #   Method to call on the item to obtain its hash.
    def initialize( options = {} )
        @options = DEFAULT_OPTIONS.merge( options )
        @hasher  = @options[:hasher].to_sym
    end

    #
    # @param    [#persistent_hash] item Item to insert.
    #
    # @return   [HashSet]  self
    #
    def <<( item )
        @collection << calculate_hash( item )
        self
    end
    alias :add :<<

    #
    # @param    [#persistent_hash] item Item to delete.
    #
    # @return   [HashSet]  self
    #
    def delete( item )
        @collection.delete( calculate_hash( item ) )
        self
    end

    #
    # @param    [#persistent_hash] item Item to check.
    #
    # @return   [Bool]
    #
    def include?( item )
        @collection.include? calculate_hash( item )
    end

    def empty?
        @collection.empty?
    end

    def size
        @collection.size
    end

    def clear
        @collection.clear
    end

    private

    def calculate_hash( item )
        item.send @hasher
    end

end

end
end
