=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Boolean option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Component::Options::Bool < Arachni::Component::Options::Base

    TRUE_REGEX   = /^(y|yes|t|1|true|on)$/i
    VALID_REGEXP = /^(y|yes|n|no|t|f|0|1|true|false|on)$/i

    def valid?
        return false if !super
        effective_value.to_s.match( VALID_REGEXP )
    end

    def normalize
        effective_value.to_s =~ TRUE_REGEX
    end

    def true?
        normalize
    end

    def false?
        !true?
    end

    def type
        :bool
    end

end
