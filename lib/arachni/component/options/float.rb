=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Floating point option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Float < Arachni::Component::Options::Base

    def normalize
        Float( value ) rescue nil
    end

    def valid?
        super && normalize
    end

    def type
        'float'
    end

end
