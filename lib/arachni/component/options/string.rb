=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Mult-byte character string option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Component::Options::String < Arachni::Component::Options::Base

    def normalize
        effective_value.to_s
    end

    def type
        :string
    end

end
