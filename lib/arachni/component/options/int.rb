=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Integer option.
#
###
class Arachni::Component::Options::Int < Arachni::Component::Options::Base
    def type
        'integer'
    end

    def normalize( value )
        if value.to_s.match( /^0x[a-fA-F\d]+$/ )
            value.to_i( 16 )
        elsif value.to_s.match( /^\d+$/ )
            value.to_i
        end
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !normalize( value ).to_s.match( /^\d+$/ )
            return false
        end

        super
    end
end
