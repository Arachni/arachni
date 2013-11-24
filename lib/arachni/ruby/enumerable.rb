=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Adds {#realsize}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Enumerable

    # @return   [Integer]   {#realsize} of self + sum of all {#realsize}s of all entries in the collection
    def realsize
        reduce( super( false ) ) { |s, e| s += e.realsize }
    end

end
