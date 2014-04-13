=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'socket'

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Address < Arachni::Component::Options::Base

    def valid?
        return false if !super
        !!IPSocket.getaddress( effective_value ) rescue false
    end

    def type
        'address'
    end

end
