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
# Cache manager -- stores, retrieves, removes and prunes objects.
#
# The cache will be pruned upon storage operations, removing old entries
# to make room for new ones, if {#max_size} is about to be exceeded.
#
# The pruning strategy depends on the selected mode of operation; the available modes are:
# * +Least Recently Used+ (+LRU+) -- Generally the most desired mode under normal circumstances,
#   although it does not satisfy high-performance requirements due to the overhead of
#   maintaining entry ages.
#   Discards the least recently used entries in order to make room for new ones.
#
# * +Random Replacement+ (+RR+) -- Better suited for high-performance situations,
#   discards entries at random in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Cache

    VALID_MODES = [
        # Random Replacement
        :rr,

        # Least Recently Used
        :lru
    ]

    # @return    [Integer]   maximum cache size
    attr_accessor :max_size

    #
    # @return    [Symbol]   current mode of operation
    #
    # @see VALID_MODES
    #
    attr_reader :mode

    #
    # @param    [Integer, nil]  max_size    Maximum size of the cache (+nil+ means unlimited).
    #   Once the size of the cache exceeds +max_size+, the pruning phase will be initiated.
    #
    #   If no +max_size+ has been provided the cache will behave like a +Hash+
    #   which holds duplicates of everything it stores -- instead of references.
    #
    # @param    [Symbol]   mode    Mode of operation.
    #
    # @see VALID_MODES
    #
    def initialize( max_size = nil, mode = :lru )
        @max_size = max_size

        if !VALID_MODES.include?( mode )
            vm = VALID_MODES.map( &:inspect ).join( ', ' )
            fail( 'Invalid mode of operation, valid modes: ' + vm )
        end

        @mode = mode

        @cache = {}
        @keys  = []
        @lru   = []
    end

    #
    # @return   [Arachni::Cache]    instance in +Random Replacement+ mode
    #
    # @see #initialize
    #
    def self.rr( max_size = nil )
        new( max_size, :rr )
    end

    #
    # @return   [Arachni::Cache]    instance in +Least Recently Used+ mode
    #
    # @see #initialize
    #
    def self.lru( max_size = nil )
        new( max_size, :lru )
    end

    # @return   [Bool]  +true+ if in LRU mode, +false+ otherwise
    def lru?
        @mode == :lru
    end

    # @return   [Bool]  +true+ if in RR mode, +false+ otherwise
    def rr?
        @mode == :rr
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
        already_in = rr? && include?( k )

        cache[k] = v

        @keys << k if !already_in && rr?

        if capped?
            renew( k ) if lru?
            prune
        end

        v
    end
    alias :[]= :store

    #
    # @param    [Object]    k   entry key
    #
    # @return   [Object, nil]   value for key +k+, +nil+ if there is no key +k+
    #
    def []( k )
        #duplicate( cache[k] )
        cache[k]
    ensure
        renew( k ) if lru?
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
    # Removed entry with key +k+ from the cache.
    #
    # @param    [Object]    k   key
    #
    # @return   [Object, nil]  value for key +k+, nil if there is no key +k+
    #
    def delete( k )
        @lru.delete( k ) if lru?
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

    def renew( k )
        @lru.unshift( @lru.delete( k ) || k )
    end

    def random_key
        # make sure that we don't get the last key
        @keys.delete_at( rand( size - 1 ) )
    end

    def prune
        if lru?
            delete( @lru.pop ) while size > max_size
        else
            delete( random_key ) while size > max_size
        end
    end

end
