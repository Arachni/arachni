=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Network port option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::Port < Arachni::Component::Options::Base

    def normalize
        effective_value.to_i
    end

    def valid?
        return false if !super
        (1..65535).include?( normalize )
    end

    def type
        :port
    end

end
