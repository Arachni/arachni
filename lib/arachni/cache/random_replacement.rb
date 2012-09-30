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
# Random Replacement cache implementation.
#
# Better suited for low-latency operations, discards entries at random
# in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Cache::RandomReplacement < Arachni::Cache::Base

    # @see Arachni::Cache::Base#initialize
    def initialize( * )
        super
        @keys = []
    end

    # @see Arachni::Cache::Base#store
    def store( k, v )
        already_in = include?( k )

        super( k, v )
    ensure
        @keys << k if !already_in
    end

    private

    def prune_candidate
        @keys.delete_at( rand( size ) )
    end

    def prune
        delete( prune_candidate )
    end

end
