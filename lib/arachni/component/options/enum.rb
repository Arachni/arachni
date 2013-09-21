=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Enum option.
#
###
class Arachni::Component::Options::Enum < Arachni::Component::Options::Base
    def type
        'enum'
    end

    def valid?( value = self.value )
        return false if empty_required_value?( value )
        value && self.enums.include?( value.to_s )
    end

    def normalize( value = self.value )
        return nil if !self.valid?( value )
        value.to_s
    end

    def desc=( value )
        self.desc_string = value
        self.desc
    end

    def desc
        if self.enums
            str = self.enums.join( ', ' )
        end
        "#{self.desc_string || @desc || ''} (accepted: #{str})"
    end

    protected
    attr_accessor :desc_string # :nodoc:
end
