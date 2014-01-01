=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni
module Support::Buffer

#
# Base buffer class to be extended by more specialised implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Base

    # @return   [Integer]   Maximum buffer size.
    attr_reader :max_size

    #
    # @param    [Integer]  max_size  Maximum buffer size -- won't be enforced.
    # @param    [#<<, #|, #clear, #size, #empty?]   type      Internal storage class to use.
    #
    def initialize( max_size = nil, type = Array )
        @buffer    = type.new
        @max_size  = max_size

        @on_flush_blocks      = []
        @on_push_blocks       = []
        @on_batch_push_blocks = []
    end

    #
    # Calls {#on_push} blocks with the given object and pushes an object to the buffer.
    #
    # @param    [Object]    obj object to push
    #
    def <<( obj )
        call_on_push_blocks obj
        @buffer << obj
        self
    end
    alias :push :<<

    #
    # Calls {#on_batch_push} blocks with the given list and merges the buffer
    # with the contents of a list.
    #
    # @param    [#|]    list list of objects
    #
    def batch_push( list )
        call_on_batch_push_blocks list
        @buffer |= list
        self
    end

    # @return   [Integer]   amount of object in the buffer
    def size
        @buffer.size
    end

    # @return   [Bool]  `true` if the buffer is empty, `false` otherwise
    def empty?
        @buffer.empty?
    end

    # @return   [Bool]  `true` if the buffer is full, `false` otherwise
    def full?
        !!(max_size && size >= max_size)
    end

    #
    # Calls {#on_flush} blocks with the buffer and then empties it.
    #
    # @return   current buffer
    #
    def flush
        buffer = @buffer.dup
        call_on_flush_blocks buffer
        buffer
    ensure
        @buffer.clear
    end

    # @param    [Block] block   block to call on {#push}
    def on_push( &block )
        @on_push_blocks << block
        self
    end

    # @param    [Block] block   block to call on {#batch_push}
    def on_batch_push( &block )
        @on_batch_push_blocks << block
        self
    end

    # @param    [Block] block   block to call on {#flush}
    def on_flush( &block )
        @on_flush_blocks << block
        self
    end

    private
    def call_on_flush_blocks( *args )
        @on_flush_blocks.each { |b| b.call *args }
    end

    def call_on_push_blocks( *args )
        @on_push_blocks.each { |b| b.call *args }
    end

    def call_on_batch_push_blocks( *args )
        @on_batch_push_blocks.each { |b| b.call *args }
    end

end
end
end
