=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Network port option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Port < Arachni::Component::Options::Base

    def normalize
        value.to_i
    end

    def valid?
        return false if !super
        (1..65535).include?( normalize )
    end

    def type
        'port'
    end

end
