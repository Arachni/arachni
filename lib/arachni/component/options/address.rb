=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'socket'

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Component::Options::Address < Arachni::Component::Options::Base

    def valid?
        return false if !super
        !!IPSocket.getaddress( effective_value ) rescue false
    end

    def type
        :address
    end

end
