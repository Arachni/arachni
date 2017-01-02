=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Glob

    def self.to_regexp( glob )
        escaped = Regexp.escape( glob ).gsub( '\*', '.*?' )
        Regexp.new( "^#{escaped}$", Regexp::IGNORECASE )
    end

    attr_reader :regexp

    def initialize( glob )
        @regexp = self.class.to_regexp( glob )
    end

    def =~( str )
        !!(str =~ @regexp)
    end
    alias :matches? :=~
    alias :match? :matches?

end

end
end
