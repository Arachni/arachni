=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# URL option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::URL < Arachni::Component::Options::Base

    def normalize
        Arachni::URI( effective_value )
    end

    def valid?
        return false if !super
        IPSocket.getaddress( normalize.host ) rescue false
    end

    def type
        'url'
    end

end
