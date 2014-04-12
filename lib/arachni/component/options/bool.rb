=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Boolean option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Bool < Arachni::Component::Options::Base

    TRUE_REGEX   = /^(y|yes|t|1|true|on)$/i
    VALID_REGEXP = /^(y|yes|n|no|t|f|0|1|true|false|on)$/i

    def valid?
        return false if !super
        value.to_s.match( VALID_REGEXP )
    end

    def normalize
        value.to_s =~ TRUE_REGEX
    end

    def true?
        normalize
    end

    def false?
        !true?
    end

    def type
        'bool'
    end

end
