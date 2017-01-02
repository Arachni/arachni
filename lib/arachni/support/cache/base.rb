=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# Base cache implementation -- stores, retrieves and removes entries.
#
# The cache will be pruned (call {#prune}) upon storage operations, removing
# old entries to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Base

    # @return    [Integer]
    #   Maximum cache size.
    attr_reader :max_size

    # @param  [Integer, nil]  max_size
    #   Maximum size of the cache (must be > 0, `nil` means unlimited).
    #   Once the size of the cache is about to exceed `max_size`, the pruning
    #   phase will be initiated.
    def initialize( max_size = nil )
        self.max_size = max_size
        @cache = {}
    end

    def max_size=( max )
        @max_size = if !max
            nil
        else
            fail( 'Maximum size must be greater than 0.' ) if max <= 0
            max
        end
    end

    # @return   [Bool]
    #   `true` is there is no size limit, `false` otherwise
    def uncapped?
        !capped?
    end

    # @return   [Bool]
    #   `true` is there is a size limit, `false`` otherwise
    def capped?
        !!max_size
    end

    # Uncaps the cache {#max_size} limit
    def uncap
        @max_size = nil
    end

    # @return   [Integer]
    #   Number of entries in the cache.
    def size
        @cache.size
    end

    # Storage method.
    #
    # @param    [Object]    k
    #   Entry key.
    # @param    [Object]    v
    #   Object to store.
    #
    # @return   [Object]    `v`
    def store( k, v )
        store_with_internal_key( make_key( k ), v )
    end

    # @see {#store}
    def []=( k, v )
        store( k, v )
    end

    # Retrieving method.
    #
    # @param    [Object]    k
    #   Entry key.
    #
    # @return   [Object, nil]
    #   Value for key `k`, `nil` if there is no key `k`.
    def []( k )
        get_with_internal_key( make_key( k ) )
    end

    # @note If key `k` exists, its corresponding value will be returned.
    #   If not, the return value of `block` will be assigned to key `k` and that
    #   value will be returned.
    #
    # @param    [Object]    k
    #   Entry key.
    #
    # @return   [Object]
    #   Value for key `k` or `block.call` if key `k` does not exist.
    def fetch( k, &block )
        k = make_key( k )

        @cache.include?( k ) ?
            get_with_internal_key( k ) :
            store_with_internal_key( k, block.call )
    end

    # @return   [Bool]
    #   `true` if cache includes an entry for key `k`, false otherwise.
    def include?( k )
        @cache.include?( make_key( k ) )
    end

    # @return   [Bool]
    #   `true` if cache is empty, false otherwise.
    def empty?
        @cache.empty?
    end

    # @return   [Bool]
    #   `true` if cache is not empty, `false` otherwise.
    def any?
        !empty?
    end

    # Removes entry with key `k` from the cache.
    #
    # @param    [Object]    k
    #   Key.
    #
    # @return   [Object, nil]
    #   Value for key `k`, `nil` if there is no key `k`.
    def delete( k )
        @cache.delete( make_key( k ) )
    end

    # Clears/empties the cache.
    def clear
        @cache.clear
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        @cache.hash
    end

    def dup
        deep_clone
    end

    private

    def store_with_internal_key( k, v )
        prune while capped? && (size > max_size - 1)

        @cache[k] = v
    end

    def get_with_internal_key( k )
        @cache[k]
    end

    def make_key( k )
        k.hash
    end

    def cache
        @cache
    end

    # Called to make room when the cache is about to reach its maximum size.
    #
    # @abstract
    def prune
        fail NotImplementedError
    end

end
end
end
