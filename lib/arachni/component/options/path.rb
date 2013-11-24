=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Network address option.
#
###
class Arachni::Component::Options::Path < Arachni::Component::Options::Base
    def type
        'path'
    end

    def valid?( value )
        return false if empty_required_value?( value )

        if value && !value.empty? && !File.exists?( value )
            return false
        end

        super
    end
end
