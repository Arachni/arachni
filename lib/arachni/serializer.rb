=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'msgpack'

module Arachni

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Serializer

    WHITELIST = Set.new([])

    def dump( object )
        return object.to_msgpack if object.respond_to? :to_msgpack
        MessagePack.dump( class: object.class.to_s, data: object.to_serializer_data )
    end

    def load( dump )
        data = MessagePack.load( dump )

        if data.is_a?( Hash ) && data.include?( 'class' ) && data.include?( 'data' )
            return constantize( data['class'] ).from_serializer_data( data['data'] )
        end

        data
    end

    private

    def constantize( klass )
        namespaces = klass.split( '::' )

        parent = Object
        namespaces.each do |name|
            parent = parent.const_get( name.to_sym )
        end

        parent
    end

    extend self
end
end
