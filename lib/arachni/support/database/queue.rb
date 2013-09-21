=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Support::Database

    #
    # Flat-file Queue implementation
    #
    # Behaves pretty much like a Ruby Queue however it transparently serializes and
    # saves its values to the file-system under the OS's temp directory.
    #
    # It's pretty useful when you want to reduce memory footprint without
    # having to refactor any code since it behaves just like Ruby's implementation.
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      
    # @version 0.1
    #
    class Queue < Base

        #
        # @see Arachni::Database::Base#initialize
        #
        def initialize( *args )
            super( *args )
            @q = ::Queue.new
        end

        #
        # Adds an object to the queue.
        #
        # @param    [Object]    obj
        #
        def <<( obj )
            @q << dump( obj )
        end
        alias :push :<<
        alias :enq :<<

        #
        # Removes an object from the Queue and returns it.
        #
        # @return   [Object]
        #
        def pop
            return load_and_delete_file( @q.pop )
        end
        alias :deq :pop
        alias :shift :pop

        #
        # Size of the Queue, the number of objects it currently holds.
        #
        # @return   [Integer]
        #
        def size
            @q.size
        end
        alias :length :size

        #
        # True if the Queue if empty, false otherwise.
        #
        # @return   [Bool]
        #
        def empty?
            @q.empty?
        end

        #
        # Removes all objects from the Queue.
        #
        def clear
            while( !@q.empty? )
                path = @q.pop
                next if !path
                delete_file( path )
            end
        end

    end

end
end
