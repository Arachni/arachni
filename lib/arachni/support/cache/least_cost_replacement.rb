=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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
# Least Cost Replacement cache implementation.
#
# Maintains 3 cost classes (low, medium, high) ) and discards entries from the
# lowest cost classes in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class LeastCostReplacement < Base

    VALID_COSTS = [ :low, :medium, :high ]

    # @see Arachni::Cache::Base#initialize
    def initialize( * )
        super
        reset_costs
    end

    #
    # Storage method
    #
    # @param    [Object]    k   entry key
    # @param    [Object]    v   object to store
    # @param    [Symbol]    cost
    #
    # @return   [Object]    `v`
    #
    # @see VALID_COSTS
    #
    def store( k, v, cost = :low )
        fail( "invalid cost: #{cost}" ) if !valid_cost?( cost )

        super( k, v )
    ensure
        @costs[cost] << k
    end

    # @see Arachni::Cache::Base#clear
    def clear
        super
    ensure
        reset_costs
    end

    private

    def reset_costs
        @costs = {}
        VALID_COSTS.each { |c| @costs[c] = [] }
    end

    def valid_cost?( cost )
        VALID_COSTS.include?( cost )
    end

    def candidate_from_cost_class( cost_class )
        return if (costs = @costs[cost_class]).empty?
        costs.delete_at( rand( costs.size ) )
    end

    def prune_candidate
        VALID_COSTS.each do |cost|
            if c = candidate_from_cost_class( cost )
                return c
            end
        end
    end

    def prune
        delete( prune_candidate )
    end

end

end
end
