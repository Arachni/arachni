=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'msgpack'

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Serializer

    # @param    [#to_msgpack]   object
    def dump( object )
        MessagePack.dump object
    end

    # @param    [String]   dump
    def load( dump )
        MessagePack.load dump
    end

    # @param    [#to_msgpack,.from_serializer_data]   object
    def deep_clone( object )
        object.class.from_serializer_data( load( dump( object ) ) )
    end

    extend self
end
end
