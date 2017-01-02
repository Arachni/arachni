=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'socket'

# Network address option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::Address < Arachni::Component::Options::Base

    def valid?
        return false if !super
        !!IPSocket.getaddress( effective_value ) rescue false
    end

    def type
        :address
    end

end
