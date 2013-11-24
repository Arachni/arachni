=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Network address option.
#
###
class Arachni::Component::Options::Address < Arachni::Component::Options::Base
    def type
        'address'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.empty?
            require 'socket'
            begin
                ::IPSocket.getaddress( value )
            rescue
                return false
            end
        end

        super
    end
end
