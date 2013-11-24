=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Support::Cache

#
# Random Replacement cache implementation.
#
# Discards entries at random in order to make room for new ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
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
