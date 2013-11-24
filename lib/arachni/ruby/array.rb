=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Array

    #
    # @param    [#to_s, Array<#to_s>]  tags
    #
    # @return [Bool]
    #   `true` if `self` contains any of the `tags` when objects of both `self`
    #   and `tags` are converted to `String`.
    #
    def includes_tags?( tags )
        return false if !tags

        tags = [tags].flatten.compact.map( &:to_s )
        return false if tags.empty?

        (self.flatten.compact.map( &:to_s ) & tags).any?
    end

    # Recursively converts the array's string data to UTF8.
    #
    # @return [Array]
    #   Copy of `self` with all strings {String#recode recoded} to UTF8.
    def recode
        map { |v| v.respond_to?( :recode ) ? v.recode : v }
    end

    def chunk( pieces = 2 )
        return self if pieces <= 0

        len    = self.length
        mid    = len / pieces
        chunks = []
        start  = 0

        1.upto( pieces ) do |i|
            last = start + mid
            last = last - 1 unless len % pieces >= i
            chunks << self[ start..last ] || []
            start = last + 1
        end

        chunks
    end

end
