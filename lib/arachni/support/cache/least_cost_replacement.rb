=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# Least Cost Replacement cache implementation.
#
# Maintains 3 cost classes (low, medium, high) ) and discards entries from the
# lowest cost classes in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class LeastCostReplacement < Base

    VALID_COSTS = [ :low, :medium, :high ]

    # @see Arachni::Cache::Base#initialize
    def initialize( * )
        super
        reset_costs
    end

    # Storage method
    #
    # @param    [Object]    k
    #   Entry key.
    # @param    [Object]    v
    #   Object to store.
    # @param    [Symbol]    cost
    #
    # @return   [Object]    `v`
    #
    # @see VALID_COSTS
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
