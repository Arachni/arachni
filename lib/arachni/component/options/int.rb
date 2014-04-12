=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Integer option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Int < Arachni::Component::Options::Base

    def normalize
        value.to_i
    end

    def valid?
        return false if !super
        value.to_s =~ /^\d+$/
    end

    def type
        'integer'
    end

end
