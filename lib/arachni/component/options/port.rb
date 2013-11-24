=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Network port option.
#
###
class Arachni::Component::Options::Port < Arachni::Component::Options::Base
    def type
        'port'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.to_s.empty? &&
            ((!value.to_s.match( /^\d+$/ ) || value.to_i <= 0 || value.to_i > 65535))
            return false
        end

        super
    end
end
