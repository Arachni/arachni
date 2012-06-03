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

module Arachni::Cache

#
# Base cache implementation -- stores, retrieves and removes entries.
#
# The cache will be pruned (call {#prune}) upon storage operations, removing old entries
# to make room for new ones, while the cache {#size} is greater than {#max_size}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
#
class Base

    # @return    [Integer]   maximum cache size
    attr_accessor :max_size

    #
    # @param    [Integer, nil]  max_size    Maximum size of the cache (+nil+ means unlimited).
    #   Once the size of the cache exceeds +max_size+, the pruning phase will be initiated.
    #
    #   If no +max_size+ has been provided the cache will behave like a +Hash+
    #   which holds duplicates of everything it stores -- instead of references.
    #
    def initialize( max_size = nil )
        @max_size = max_size
        @cache = {}
    end

    # @return   [Bool]  +true+ is there is no size limit, +false+ otherwise
    def uncapped?
        !capped?
    end

    # @return   [Bool]  +true+ is there is a size limit, +false+ otherwise
    def capped?
        !!max_size
    end

    # Uncaps the cache {#max_size} limit
    def uncap
        @max_size = nil
    end

    # @return   [Integer]   number of entries in the cache
    def size
        cache.size
    end

    #
    # Storage method
    #
    # @param    [Object]    k   entry key
    # @param    [Object]    v   object to store
    #
    # @return   [Object]    +v+
    #
    def store( k, v )
        cache[k] = v
    ensure
        prune while capped? && size > max_size
    end

    # @see {#store}
    def []=( k, v )
        store( k, v )
    end

    #
    # Retrieving method
    #
    # @param    [Object]    k   entry key
    #
    # @return   [Object, nil]   value for key +k+, +nil+ if there is no key +k+
    #
    def []( k )
        cache[k]
    end

    #
    # If key +k+ exists, its corresponding value will be returned.
    #
    # If not, the return value of +block+ will be assigned to key +k+ and that
    # value will be returned.
    #
    # @param    [Object]    k   entry key
    #
    # @return   [Object]    value of key +k+ or +block.call+ if key +k+ does not exist.
    #
    def fetch_or_store( k, &block )
        include?( k ) ? self[k] : store( k, block.call )
    end

    # @return   [Bool]  +true+ if cache includes an entry for key +k+, false otherwise
    def include?( k )
        cache.include?( k )
    end

    # @return   [Bool]  +true+ if cache is empty, false otherwise
    def empty?
        cache.empty?
    end

    # @return   [Bool]  +true+ if cache is not empty, false otherwise
    def any?
        !empty?
    end

    #
    # Removes entry with key +k+ from the cache.
    #
    # @param    [Object]    k   key
    #
    # @return   [Object, nil]  value for key +k+, nil if there is no key +k+
    #
    def delete( k )
        cache.delete( k )
    end

    # clears/empties the cache
    def clear
        cache.clear
    end

    private

    def cache
        @cache
    end

    def duplicate( v )
        if v.respond_to?( :dup )
            v.dup rescue v
        else
            v
        end
    end

    #
    # Called to make room when the cache reaches its maximum size.
    #
    # @abstract
    #
    def prune
    end

end
end
