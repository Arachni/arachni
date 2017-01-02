=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'digest/sha1'

module Arachni
module Support::Database

# Flat-file Hash implementation
#
# Behaves pretty much like a Ruby Hash however it transparently serializes and
# saves its values to the file-system under the OS's temp directory.
#
# It's not interchangeable with Ruby's Hash as it lacks a lot of the
# stdlib methods.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Hash < Base

    # @see Arachni::Database::Base#initialize
    def initialize( *args )
        super( *args )

        # holds the internal representation of the Hash
        # same keys as self but the values are actually pointing to filepaths
        # where the real values are being stores
        @h = ::Hash.new

        # holds a key-value pair of self with digests as values
        # in order to allow comparisons without requiring to load
        # the actual values from their files.
        @eql_h = ::Hash.new
    end

    # Associates the given value  with the given key.
    #
    # @param    [Object]    k
    #   Key.
    # @param    [Object]    v
    #   Value.
    #
    # @return   [Object]
    #   `v`.
    def []=( k, v )
        @h[k] = dump( v ) do |serialized|
            @eql_h[k] = eql_hash( serialized )
        end
    end
    alias :store :[]=

    # @param    [Obj]   k   key
    #
    # @return   [Object]
    #   Object corresponding to the key object, `nil` otherwise.
    def []( k )
        load( @h[k] ) if @h[k]
    end

    # @param    [Object]    k
    #   Key.
    #
    # @return   [Array]
    #   Array containing the given key and its value.
    def assoc( k )
        return if !@h[k]
        [ k, self[k] ]
    end

    # @param    [Object]    v
    #   Value.
    #
    # @return   [Array]
    #   Array containing the key for the given value and that value.
    def rassoc( v )
        return if !value?( v )
        [ key( v ), v ]
    end

    # Removes an entry by key and returns its value.
    #
    # If the key doesn't exist and a block has been provided it's passed
    # the key and the method returns the result of that block.
    #
    # @param    [Object]    k
    #   Key.
    #
    # @return   [Object]
    def delete( k, &block )
        if @h[k]
            obj = load_and_delete_file( @h[k] )
            @h.delete( k )
            @eql_h.delete( k )
            return obj
        else
            block.call( k ) if block_given?
        end
    end

    # Removes the first key-value pair from the hash and returns it as a array,
    #
    # @return   [Array]
    def shift
        k, v = @h.first
        [ k, delete( k ) ]
    end

    # Calls block with each key-value pair.
    #
    # If a block has been given it retuns self.
    # If no block has been given it returns an enumerator.
    #
    # @param    [Proc]      block
    def each( &block )
        if block_given?
            @h.each { |k, v| block.call( [ k, self[k] ] ) }
            self
        else
            enum_for( :each )
        end
    end
    alias :each_pair :each

    # Calls block with each key.
    #
    # If a block has been given it returns self.
    # If no block has been given it returns an enumerator.
    #
    # @param    [Proc]      block
    def each_key( &block )
        if block_given?
            @h.each_key( &block )
            self
        else
            enum_for( :each_key )
        end
    end

    # Calls block with each value.
    #
    # If a block has been given it returns `self`.
    # If no block has been given it returns an enumerator.
    #
    # @param    [Proc]      block
    def each_value( &block )
        if block_given?
            @h.keys.each { |k| block.call( self[k] ) }
            self
        else
            enum_for( :each_value )
        end
    end

    # @return   [Array]
    #   Keys.
    def keys
        @h.keys
    end

    # @param    [Object]    val
    #
    # @return   [Object]    key
    #   key for the given value.
    def key( val )
        return if !value?( val )
        each { |k, v| return k if val == self[k] }
        nil
    end

    # @return   [Array]
    #   Values.
    def values
        each_value.to_a
    end

    # @return   [Bool]
    #   `true` if the given key exists in the hash, `false` otherwise.
    def include?( k )
        @h.include?( k )
    end
    alias :member? :include?
    alias :key? :include?
    alias :has_key? :include?

    # @return   [Bool]
    #   `true` if the given value exists in the hash, `false` otherwise.
    def value?( v )
        each_value { |val| return true if val == v }
        false
    end

    # Merges the contents of self with the contents of the given hash and
    # returns them in a new object.
    #
    # @param    [Hash]  h
    #
    # @return   [Arachni::Database::Hash]
    def merge( h )
        self.class.new( serializer ).merge!( self ).merge!( h )
    end

    # Merges self with the contents of the given hash and returns self.
    #
    # If the given Hash is of the same type as self then the values will
    # not be loaded during the merge in order to keep memory usage down.
    #
    # If the given Hash is any other kind of object it will be coerced
    # to a Hash by calling 'to_hash' on it and the merging it with self.
    #
    # @param    [Hash]  h
    def merge!( h )
        if !h.is_a?( self.class )
            h.to_hash.each do |k, v|
                delete( k ) if @h.include?( k )
                self[k] = v
            end
        else
            h._internal.each do |k, v|
                delete( k ) if @h.include?( k )
                @h[k] = v
            end
            @eql_h.merge!( h._eql_h )
        end
        self
    end
    alias :update :merge!

    # @return   [Hash]
    #   `self` as Ruby Hash
    def to_hash
        h = {}
        each { |k, v| h[k] = v }
        h
    end
    alias :to_h :to_hash

    # @return   [Array]
    #   `self` as a Ruby Array.
    def to_a
        to_hash.to_a
    end

    # @return   [Integer]
    #   Number of objects.
    def size
        @h.size
    end
    alias :length :size

    # @return   [Bool]
    #   `true` if the Hash if empty, `false` otherwise.
    def empty?
        @h.empty?
    end

    # Removes all objects.
    def clear
        @h.values.each { |filepath| delete_file( filepath ) }
        @h.clear
    end

    # @note If the given hash is not of the same type as self it will be coerced
    #   to a Ruby Hash by calling 'to_hash' on it.
    #
    # @return  [Bool]
    #   `true` if self and the given hash contain the same key-pair values.
    def ==( h )
        if !h.is_a?( self.class )
            eql = {}
            h.to_hash.each { |k, v| eql[k] = eql_hash( serialize( v ) ) }
            @eql_h == eql
        else
            @eql_h == h._eql_h
        end
    end
    alias :eql? :==

    # It will return a Ruby Hash with the same values as self but
    # with filepaths as values (pointing to the files that store them).
    #
    # This is used for efficient merging, i.e. without requiring to load
    # the actual values when merging 2 objects.
    #
    # @return   [Hash]
    #   Internal representation of `self`.
    def _internal
        @h.dup
    end

    def _eql_h
        @eql_h.dup
    end

    private

    def eql_hash( str )
        Digest::SHA1.hexdigest( str )
    end

end

end
end
