=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Issue

module Severity

# Represents an {Issue}'s severity.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Base
    include Comparable

    def initialize( severity )
        @severity = severity.to_s.downcase.to_sym
    end

    def <=>( other )
        ORDER.rindex( other.to_sym ) <=> ORDER.rindex( to_sym )
    end

    def to_sym
        @severity
    end

    def to_s
        @severity.to_s
    end
end

end
end
end
