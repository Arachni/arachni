=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Support::Cache

#
# Random Replacement cache implementation.
#
# Better suited for low-latency operations, discards entries at random
# in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Preference < Base

    #
    # Storage method
    #
    # @param    [Object]    k   entry key
    # @param    [Object]    v   object to store
    #
    # @return   [Object]    `v`
    #
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
