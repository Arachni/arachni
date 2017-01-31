=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Buffer

#
# Base buffer class to be extended by more specialised implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
class Base
    include Support::Mixins::Observable

    # @!method on_push( &block )
    #   @param    [Block] block   block to call on {#push}
    advertise :on_push

    # @!method on_batch_push( &block )
    #   @param    [Block] block   block to call on {#batch_push}
    advertise :on_batch_push

    # @!method on_flush( &block )
    #   @param    [Block] block   block to call on {#flush}
    advertise :on_flush

    # @return   [Integer]   Maximum buffer size.
    attr_reader :max_size

    # @param    [Integer]  max_size
    #   Maximum buffer size -- won't be enforced.
    # @param    [#<<, #|, #clear, #size, #empty?]   type
    #   Internal storage class to use.
    def initialize( max_size = nil, type = Array )
        super()
        @buffer    = type.new
        @max_size  = max_size
    end

    # @note Calls {#on_push} blocks with the given object and pushes an object
    #   to the buffer.
    #
    # @param    [Object]    obj
    #   Object to push.
    def <<( obj )
        notify_on_push obj
        @buffer << obj
        self
    end
    alias :push :<<

    # @note Calls {#on_batch_push} blocks with the given list and merges the
    #   buffer with the contents of a list.
    #
    # @param    [#|]    list
    #   List of objects
    def batch_push( list )
        notify_on_batch_push list
        @buffer |= list
        self
    end

    # @return   [Integer]
    #   Number of object in the buffer.
    def size
        @buffer.size
    end

    # @return   [Bool]
    #   `true` if the buffer is empty, `false` otherwise.
    def empty?
        @buffer.empty?
    end

    # @return   [Bool]
    #   `true` if the buffer is full, `false` otherwise.
    def full?
        !!(max_size && size >= max_size)
    end

    # @note Calls {#on_flush} blocks with the buffer and then empties it.
    #
    # @return   current buffer
    def flush
        buffer = @buffer.dup
        notify_on_flush buffer
        buffer
    ensure
        @buffer.clear
    end

end
end
end
