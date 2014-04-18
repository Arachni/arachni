=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Overloads the {Object} class providing a {#deep_clone} method.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Object

    #
    # Deep-clones self using a Marshal dump-load.
    #
    # @return   [Object]    Duplicate of self.
    #
    def deep_clone
        Marshal.load( Marshal.dump( self ) )
    end

    def to_msgpack( *args )
        if respond_to? :to_serializer_data
            return to_serializer_data.to_msgpack( *args )
        end

        super
    end

    #
    # Attempts to approximate the real size of self by summing up the size of
    # all its instance variables' values and names.
    #
    # @param    [Bool]  invoke_size
    #   Whether or not to include self's `size` in the return value.
    #
    # @return   [Integer]  Size of self.
    #
    def realsize( invoke_size = true )
        return 1 if nil?

        sz = 0
        sz = size rescue 0 if invoke_size

        ivs = instance_variables
        return sz if ivs.empty?

        ivs.reduce( sz ) do |s, iv|
            v = instance_variable_get( iv )
            s += begin
                rs = v.realsize
                rs > 0 ? rs : v.size
            rescue => e
                ap e
                0
            end
            s += iv.size
        end
    end

end
