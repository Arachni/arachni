=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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

    private

    def get_with_internal_key( k )
        return if !@cache.include? k
        renew( k )

        super k
    end

    def renew( internal_key )
        @cache[internal_key] = @cache.delete( internal_key )
    end

end
end
end
