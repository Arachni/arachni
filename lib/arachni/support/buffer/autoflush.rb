=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Buffer

# A buffer implementation which flushes itself when it gets full or a number
# of push attempts is reached between flushes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class AutoFlush < Base

    attr_reader :max_pushes

    # @param    [Integer]  max_size
    #   Maximum buffer size -- a flush will be triggered when that limit is
    #   reached.
    # @param    [Integer]  max_pushes
    #   Maximum number of pushes between flushes.
    # @param    [#<<, #|, #clear, #size, #empty?]   type
    #   Internal storage class to use.
    def initialize( max_size = nil, max_pushes = nil, type = Array )
        super( max_size, type )

        @max_pushes = max_pushes
        @pushes     = 0
    end

    def <<( *args )
        super( *args )
    ensure
        handle_push
    end

    def batch_push( *args )
        super( *args )
    ensure
        handle_push
    end

    def flush
        super
    ensure
        @pushes = 0
    end

    private

    def handle_push
        @pushes += 1
        flush if flush?
    end

    def flush?
        !!(full? || push_limit_reached?)
    end

    def push_limit_reached?
        max_pushes && @pushes >= max_pushes
    end

end
end
end
