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
    #   {#compress Compressed} `object` dump.
    def dump( object )
        compress( MessagePack.dump( object ) )
    end

    # @param    [String]   dump
    #   {#dump Dumped} object.
    # @return   [Object]
    def load( dump )
        MessagePack.load( decompress( dump ) )
    end

    # Simulates an object's over-the-wire transmission by {#dump dumping}
    # and then {#load loading}.
    #
    # @param    [#to_rpc_data,.from_rpc_data]   object
    # @return   [Object]
    #   Data that the peer would receive.
    def rpc_data( object )
        load( dump( object ) )
    end

    # @param    [#to_rpc_data,.from_rpc_data]   object
    # @return   [Object]
    def deep_clone( object )
        object.class.from_rpc_data rpc_data( object )
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
