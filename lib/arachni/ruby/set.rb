=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'set'

class Set
    def shift
        return if @hash.empty?

        key = @hash.first.first
        @hash.delete key
        key
    end
end
