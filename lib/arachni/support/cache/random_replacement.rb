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
# Discards entries at random in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class RandomReplacement < Base

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

    def clear
        super
        @keys.clear
    end

    private

    def prune_candidate
        @keys.delete_at( rand( size ) )
    end

    def prune
        delete( prune_candidate )
    end

end

end
end
