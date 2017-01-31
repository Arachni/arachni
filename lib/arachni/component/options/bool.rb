=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
