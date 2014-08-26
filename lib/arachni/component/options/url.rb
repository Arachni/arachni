=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# URL option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::URL < Arachni::Component::Options::Base

    def normalize
        Arachni::URI( effective_value )
    end

    def valid?
        return false if !super
        IPSocket.getaddress( normalize.host ) rescue false
    end

    def type
        :url
    end

end
