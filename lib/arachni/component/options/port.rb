=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Network port option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
