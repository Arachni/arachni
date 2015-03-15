=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# Least Recently Used cache implementation.
#
# Generally, the most desired mode under most circumstances.
# Discards the least recently used entries in order to make room for newer ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class LeastRecentlyUsed < Base

    # @see Arachni::Cache::Base#[]
    def []( k )
        super( k )
    ensure
        renew( k )
    end

    private

    def renew( k )
        @cache[k] = @cache.delete( k )
    end

    def prune
        @cache.delete( @cache.first.first )
    end

end
end
end
