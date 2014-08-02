=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Integer option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Component::Options::Int < Arachni::Component::Options::Base

    def normalize
        effective_value.to_i
    end

    def valid?
        return false if !super
        effective_value.to_s =~ /^\d+$/
    end

    def type
        :integer
    end

end
