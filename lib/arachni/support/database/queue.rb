=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Database

# Flat-file Queue implementation
#
# Behaves pretty much like a Ruby Queue however it transparently serializes and
# saves its entries to the file-system under the OS's temp directory **after**
# a specified {#max_buffer_size} (for in-memory entries) has been exceeded.
#
# It's pretty useful when you want to reduce memory footprint without
# having to refactor any code since it behaves just like a Ruby Queue
# implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Queue < Base

    # Default {#max_buffer_size}.
    DEFAULT_MAX_BUFFER_SIZE = 100

    # @return   [Integer]
    #   How many entries to keep in memory before starting to off-load to disk.
    attr_accessor :max_buffer_size

    # @return   [Array<Object>]
    #   Objects stored in the memory buffer.
    attr_reader :buffer

    # @return   [Array<String>]
    #   Paths to files stored to disk.
    attr_reader :disk

    # @see Arachni::Database::Base#initialize
    def initialize( *args )
        super( *args )
        @disk    = []
        @buffer  = []
        @waiting = []
        @mutex   = Mutex.new
    end

    # @note Defaults to {DEFAULT_MAX_BUFFER_SIZE}.
    #
    # @return   [Integer]
    #   How many entries to keep in memory before starting to off-load to disk.
    def max_buffer_size
        @max_buffer_size || DEFAULT_MAX_BUFFER_SIZE
    end

    # @param    [Object]    obj
    #   Object to add to the queue.
    def <<( obj )
        synchronize do
            if @buffer.size < max_buffer_size
                @buffer << obj
            else
                @disk << dump( obj )
            end

            begin
                t = @waiting.shift
                t.wakeup if t
            rescue ThreadError
                retry
            end
        end
    end
    alias :push :<<
    alias :enq :<<

    # @return   [Object]
    #   Removes an object from the queue and returns it.
    def pop( non_block = false )
        synchronize do
            loop do
                if internal_empty?
                    raise ThreadError, 'queue empty' if non_block
                    @waiting.push Thread.current
                    @mutex.sleep
                else
                    return @buffer.shift if !@buffer.empty?
                    return load_and_delete_file( @disk.shift )
                end
            end
        end
    end
    alias :deq :pop
    alias :shift :pop

    # @return   [Integer]
    #   Size of the queue, the number of objects it currently holds.
    def size
        buffer_size + disk_size
    end
    alias :length :size

    def free_buffer_size
        max_buffer_size - buffer_size
    end

    def buffer_size
        @buffer.size
    end

    def disk_size
        @disk.size
    end

    # @return   [Bool]
    #   `true` if the queue if empty, `false` otherwise.
    def empty?
        synchronize do
            internal_empty?
        end
    end

    # Removes all objects from the queue.
    def clear
        synchronize do
            @buffer.clear

            while !@disk.empty?
                path = @disk.pop
                next if !path
                delete_file path
            end
        end
    end

    def num_waiting
        @waiting.size
    end

    private

    def internal_empty?
        @buffer.empty? && @disk.empty?
    end

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

end
end
