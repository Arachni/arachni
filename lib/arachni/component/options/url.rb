=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
