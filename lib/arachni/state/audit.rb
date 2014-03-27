=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Audit
    extend Forwardable

    def initialize
        @collection = Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    [:<<, :include?, :clear, :empty?, :any?, :size].each do |method|
        def_delegator :collection, method
    end

    private

    def collection
        @collection
    end

end

end
end
