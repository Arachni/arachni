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
class LeastRecentlyUsed < LeastRecentlyPushed

    # @see Arachni::Cache::Base#[]
    def []( k )
        return if !include? k

        renew( k )
        super( k )
    end

    private

    def renew( k )
        @cache[make_key( k )] = @cache.delete( make_key( k ) )
    end

end
end
end
