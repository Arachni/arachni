=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
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
