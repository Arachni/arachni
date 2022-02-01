=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# Least Recently Pushed cache implementation.
#
# Discards the least recently pushed entries, in order to make room for newer ones.
#
# This is the cache with best performance across the board.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class LeastRecentlyPushed < Base

    private

    def prune
        @cache.delete( @cache.first.first )
    end

end
end
end
