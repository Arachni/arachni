=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# URL option.
#
###
class Arachni::Component::Options::URL < Arachni::Component::Options::Base
    def type
        'url'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.to_s.empty?
            require 'uri'
            require 'socket'
            begin
                ::IPSocket.getaddress( URI( value ).host )
            rescue
                return false
            end
        end

        super
    end
end
