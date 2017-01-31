=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Cache

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Preference < Base

    def prefer( &block )
        @preference = block
    end

    private

    def store_with_internal_key( k, v )
        prune if capped? && (size > max_size - 1)

        @cache[k] = v
    end

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
