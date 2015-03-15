=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# Random Replacement cache implementation.
#
# Better suited for low-latency operations, discards entries at random
# in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Preference < Base

    # Storage method
    #
    # @param    [Object]    k
    #   Entry key.
    # @param    [Object]    v
    #   Object to store.
    #
    # @return   [Object]
    #   `v`
    def store( k, v )
        prune if capped? && (size > max_size - 1)
        cache[k.hash] = v
    end

    def prefer( &block )
        @preference = block
    end

    private

    def find_preference
        @preference.call
    end

    def prune
        preferred = find_preference
        delete( preferred ) if preferred
    end

end

end
end
