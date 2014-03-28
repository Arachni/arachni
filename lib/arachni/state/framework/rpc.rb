=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class State
class Framework

# State information for {Arachni::RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class RPC

    # @return   [Support::LookUp::HashSet]
    attr_reader :distributed_pages

    # @return   [Set]
    attr_reader :distributed_elements

    # @return   [Support::Database::Queue]
    attr_reader :distributed_page_queue

    def initialize
        @distributed_pages = Support::LookUp::HashSet.new( hasher: :persistent_hash )

        # Stores Element::Capabilities::Auditable#audit_scope_id which already
        # return a #persistent_hash, so a simple Set is enough.
        @distributed_elements = Set.new

        @distributed_page_queue = Support::Database::Queue.new
    end

    def clear
        @distributed_pages.clear
        @distributed_elements.clear
        @distributed_page_queue.clear
    end

end

end
end
end

