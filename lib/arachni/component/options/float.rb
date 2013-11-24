=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Floating point option.
#
###
class Arachni::Component::Options::Float < Arachni::Component::Options::Base
    def type
        'float'
    end

    def normalize( value )
        begin
            Float( value )
        rescue
            nil
        end
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !normalize( value ).to_s.match( /^\d+\.\d+$/ )
            return false
        end

        super
    end

end
