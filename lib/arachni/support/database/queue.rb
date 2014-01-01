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
        @q     = ::Queue.new
        @mutex = Mutex.new
    end

    # @param    [Object]    obj Object to add to the queue.
    def <<( obj )
        synchronize { @q << dump( obj ) }
    end
    alias :push :<<
    alias :enq :<<

    # @return   [Object] Removes an object from the queue and returns it.
    def pop
        synchronize { load_and_delete_file @q.pop }
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

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

end
end
