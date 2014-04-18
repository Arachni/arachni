=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'msgpack'

module Arachni
module RPC

# Used for serialization of {RPC} messages.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Serializer

    # Compress object dumps larger than 1KB.
    COMPRESS_LARGER_THAN = 1_000

    # @param    [#to_msgpack]   object
    # @return   [String]
    #   {#compressed Compressed} `object` dump.
    def dump( object )
        compress( MessagePack.dump( object ) )
    end

    # @param    [String]   dump
    #   {#dump Dumped} object.
    # @return   [Object]
    def load( dump )
        MessagePack.load( decompress( dump ) )
    end

    # @param    [#to_msgpack,.from_serializer_data]   object
    def deep_clone( object )
        object.class.from_serializer_data( load( dump( object ) ) )
    end

    # @note Ignores strings smaller than #{COMPRESS_LARGER_THAN}.
    #
    # @param    [String]    string
    #   String to compress.
    # @return   [String]
    #   Compressed (or not) `string`.
    def compress( string )
        return string if string.size < COMPRESS_LARGER_THAN
        Zlib::Deflate.deflate string
    end

    # @note Will return the `string` as is if it was not compressed.
    #
    # @param    [String]    string
    #   String to decompress.
    # @return   [String]
    #   Decompressed string.
    def decompress( string )
        begin
            Zlib::Inflate.inflate string
        rescue Zlib::DataError
            string
        end
    end

    extend self
end

end
end
