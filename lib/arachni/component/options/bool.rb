=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

###
#
# Boolean option.
#
###
class Arachni::Component::Options::Bool < Arachni::Component::Options::Base
    TRUE_REGEX = /^(y|yes|t|1|true|on)$/i

    def type
        'bool'
    end

    def valid?( value )
        return false if empty_required_value?(value)

        if value && !value.to_s.empty? &&
            !value.to_s.match( /^(y|yes|n|no|t|f|0|1|true|false|on)$/i )
            return false
        end

        true
    end

    def normalize( value )
        if value.nil? || value.to_s.match( TRUE_REGEX ).nil?
            false
        else
            true
        end
    end

    def true?( value )
        normalize( value )
    end

    def false?( value )
        !true?( value )
    end
end
