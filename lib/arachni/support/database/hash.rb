=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'digest/sha1'

module Arachni
module Support::Database

    #
    # Flat-file Hash implementation
    #
    # Behaves pretty much like a Ruby Hash however it transparently serializes and
    # saves its values to the file-system under the OS's temp directory.
    #
    # It's not interchangeable with Ruby's Hash as it lacks a lot of the
    # stdlib methods.
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      
    # @version 0.1
    #
    class Hash < Base

        #
        # @see Arachni::Database::Base#initialize
        #
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

        #
        # Associates the given value  with the given key.
        #
        # @param    [Object]    k   key
        # @param    [Object]    v   value
        #
        # @return   [Object]    returns value
        #
        def []=( k, v )
            @h[k] = dump( v ) {
                |serialized|
                @eql_h[k] = eql_hash( serialized )
            }
        end
        alias :store :[]=

        #
        # Retrieves the value object corresponding to the key object,
        # nil otherwise.
        #
        # @param    [Obj]   k   key
        #
        # @return   [Object]
        #
        def []( k )
            load( @h[k] ) if @h[k]
        end

        #
        # Returns an array containing the given key and its value.
        #
        # @param    [Object]    k   key
        #
        # @return   [Array]
        #
        def assoc( k )
            return if !@h[k]
            [ k, self[k] ]
        end

        #
        # Returns an array containing the key for the given value and that value.
        #
        # @param    [Object]    v   value
        #
        # @return   [Array]
        #
        def rassoc( v )
            return if !value?( v )
            [ key( v ), v ]
        end

        #
        # Removes an entry by key and returns its value.
        #
        # If the key doesn't exist and a block has been provided it's passed
        # the key and the method returns the result of that block.
        #
        # @param    [Object]    k   key
        #
        # @return   [Object]
        #
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

        #
        # Removes the first key-value pair from the hash and returns it as a array,
        #
        # @return   [Array]
        #
        def shift
            k, v = @h.first
            [ k, delete( k ) ]
        end

        #
        # Calls block with each key-value pair.
        #
        # If a block has been given it retuns self.<br/>
        # If no block has been given it returns an enumerator.
        #
        # @param    [Proc]      block
        #
        def each( &block )
            if block_given?
                @h.each {
                    |k, v|
                    block.call( [ k, self[k] ] )
                }
                self
            else
                enum_for( :each )
            end
        end
        alias :each_pair :each

        #
        # Calls block with each key.
        #
        # If a block has been given it returns self.<br/>
        # If no block has been given it returns an enumerator.
        #
        # @param    [Proc]      block
        #
        def each_key( &block )
            if block_given?
                @h.each_key( &block )
                self
            else
                enum_for( :each_key )
            end
        end

        #
        # Calls block with each value.
        #
        # If a block has been given it retuns self.<br/>
        # If no block has been given it returns an enumerator.
        #
        # @param    [Proc]      block
        #
        def each_value( &block )
            if block_given?
                @h.keys.each {
                    |k|
                    block.call( self[k] )
                }
                self
            else
                enum_for( :each_value )
            end
        end

        #
        # Returns all keys as an array.
        #
        # @return   [Array]     keys
        #
        def keys
            @h.keys
        end

        #
        # Returns the key for the given value.
        #
        # @param    [Object]    val
        #
        # @return   [Object]    key
        #
        def key( val )
            return if !value?( val )
            each {
                |k, v|
                return k if val == self[k]
            }
            nil
        end

        #
        # Returns all values as an array.
        #
        # @return   [Array]     values
        #
        def values
            each_value.to_a
        end

        #
        # Returns true if the given key exists in the hash, false otherwise.
        #
        # @return   [Bool]
        #
        def include?( k )
            @h.include?( k )
        end
        alias :member? :include?
        alias :key? :include?
        alias :has_key? :include?

        #
        # Returns true if the given value exists in the hash, false otherwise.
        #
        # @return   [Bool]
        #
        def value?( v )
            each_value {
                |val|
                return true if val == v
            }
            return false
        end

        #
        # Merges the contents of self with the contents of the given hash and
        # returns them in a new object.
        #
        # @param    [Hash]  h
        #
        # @return   [Arachni::Database::Hash]
        #
        def merge( h )
            self.class.new( serializer ).merge!( self ).merge!( h )
        end

        #
        # Merges self with the contents of the given hash and returns self.
        #
        # If the given Hash is of the same type as self then the values will
        # not be loaded during the merge in order to keep memory usage down.
        #
        # If the given Hash is any other kind of object it will be coerced
        # to a Hash by calling 'to_hash' on it and the merging it with self.
        #
        # @param    [Hash]  h
        #
        def merge!( h )
            if !h.is_a?( self.class )
                h.to_hash.each {
                    |k, v|
                    delete( k ) if @h.include?( k )
                    self[k] = v
                }
            else
                h._internal.each {
                    |k, v|
                    delete( k ) if @h.include?( k )
                    @h[k] = v
                }
                @eql_h.merge!( h._eql_h )
            end
            self
        end
        alias :update :merge!

        #
        # Converts self to a Ruby Hash
        #
        # @return   [Hash]
        #
        def to_hash
            h = {}
            each { |k, v| h[k] = v }
            return h
        end
        alias :to_h :to_hash

        #
        # Converts self to a Ruby Array
        #
        # @return   [Array]
        #
        def to_a
            to_hash.to_a
        end

        #
        # Size of the Queue, the number of objects it currently holds.
        #
        # @return   [Integer]
        #
        def size
            @h.size
        end
        alias :length :size

        #
        # True if the Queue if empty, false otherwise.
        #
        # @return   [Bool]
        #
        def empty?
            @h.empty?
        end

        #
        # Removes all objects from the Queue.
        #
        def clear
            @h.values.each { |filepath| delete_file( filepath ) }
            @h.clear
        end

        #
        # Returns true if self and the given hash contain the same key-pair
        # values.
        #
        # If the given hash is not of the same type as self it will be coerced
        # to a Ruby Hash by calling 'to_hash' on it.
        #
        def ==( h )
            if !h.is_a?( self.class )
                eql = {}
                h.to_hash.each {
                    |k, v|
                    eql[k] = eql_hash( serialize( v ) )
                }
                @eql_h == eql
            else
                @eql_h == h._eql_h
            end
        end
        alias :eql? :==

        #
        # Returns the internal representation of self.
        #
        # It will return a Ruby Hash with the same values as self but
        # with filepaths as values (pointing to the files that store them).
        #
        # This is used for efficient merging, i.e. without requiring to load
        # the actual values when merging 2 objects.
        #
        # @return   [Hash]
        #
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
