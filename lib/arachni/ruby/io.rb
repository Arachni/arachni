=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class IO
    TAIL_BUF_LENGTH = 1 << 16

    # @param    [Integer]   n
    #   Amount of lines to return from the bottom of the file.
    #
    # @return   [Array<String>]
    #   `n` amount of lines from the bottom of the file.
    #
    # @see http://stackoverflow.com/questions/3024372/how-to-read-a-file-from-bottom-to-top-in-ruby/3024704#3024704
    def tail( n )
        return [] if n < 1

        seek_to = TAIL_BUF_LENGTH
        seek_to = size if seek_to > size

        seek -seek_to, IO::SEEK_END

        buf = ''
        while buf.count( "\n" ) <= n
            buf = read( seek_to ) + buf

            seek_to *= 2
            seek_to = size if seek_to > size

            seek -seek_to, IO::SEEK_CUR
        end

        buf.split( "\n" )[-n..-1]
    end
end
