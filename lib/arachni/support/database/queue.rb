=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Support::Database

# Flat-file Queue implementation
#
# Behaves pretty much like a Ruby Queue however it transparently serializes and
# saves its values to the file-system under the OS's temp directory.
#
# It's pretty useful when you want to reduce memory footprint without
# having to refactor any code since it behaves just like Ruby's implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Queue < Base

    # @see Arachni::Database::Base#initialize
    def initialize( *args )
        super( *args )
        @q       = []
        @waiting = []
        @mutex   = Mutex.new
    end

    # @param    [Object]    obj Object to add to the queue.
    def <<( obj )
        synchronize do
            @q << dump( obj )
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

    # @return   [Object] Removes an object from the queue and returns it.
    def pop( non_block = false )
        synchronize do
            loop do
                if @q.empty?
                    raise ThreadError, 'queue empty' if non_block
                    @waiting.push Thread.current
                    @mutex.sleep
                else
                    return load_and_delete_file @q.shift
                end
            end
        end
    end
    alias :deq :pop
    alias :shift :pop

    # @return   [Integer]
    #   Size of the queue, the number of objects it currently holds.
    def size
        @q.size
    end
    alias :length :size

    # @return   [Bool] `true` if the queue if empty, `false` otherwise.
    def empty?
        @q.empty?
    end

    # Removes all objects from the queue.
    def clear
        while !@q.empty?
            path = @q.pop
            next if !path
            delete_file path
        end
    end

    def num_waiting
        @waiting.size
    end

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

end
end
