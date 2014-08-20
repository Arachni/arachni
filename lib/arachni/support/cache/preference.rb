=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Support::Cache

# Random Replacement cache implementation.
#
# Better suited for low-latency operations, discards entries at random
# in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
