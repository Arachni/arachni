=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Least Recently Used cache implementation.
#
# Generally the most desired mode under normal circumstances, although it does
# not satisfy low-latency requirements due to the overhead of maintaining entry ages.
#
# Discards the least recently used entries in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Cache::LeastRecentlyUsed < Arachni::Cache::Base

    # @see Arachni::Cache::Base#initialize
    def initialize( * )
        super
        @lru = []
    end

    # @see Arachni::Cache::Base#store
    def store( k, v )
        super( k, v )
    ensure
        renew( k )
    end

    # @see Arachni::Cache::Base#[]
    def []( k )
        super( k )
    ensure
        renew( k )
    end

    # @see Arachni::Cache::Base#delete
    def delete( k )
        super( k )
    ensure
        @lru.delete( k )
    end

    # @see Arachni::Cache::Base#clear
    def clear
        super
    ensure
        @lru.clear
    end

    private

    def renew( k )
        @lru.unshift( @lru.delete( k ) || k )
    end

    def prune
        delete( @lru.pop )
    end

end
