=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'set'

module Arachni
module Support::LookUp

#
# Lightweight look-up Set implementation.
#
# It uses stores hashes of items instead of the items themselves.
#
# This leads to decreased memory consumption and faster comparisons during look-ups.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HashSet < Base

    # @param    (see Base#initialize)
    def initialize(*)
        super
        @collection = Set.new
    end

    def merge( other )
        @collection.merge other.collection
        self
    end

end

end
end
