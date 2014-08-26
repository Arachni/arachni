=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Mult-byte character string option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::String < Arachni::Component::Options::Base

    def normalize
        effective_value.to_s
    end

    def type
        :string
    end

end
