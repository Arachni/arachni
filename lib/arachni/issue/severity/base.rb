=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Issue

module Severity

# Represents an {Issue}'s severity.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
