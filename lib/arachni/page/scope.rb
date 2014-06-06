=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Page

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < HTTP::Response::Scope

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Page::Error
    end

    def initialize( page )
        super page

        @page = page
    end

    def exclude?
        return true if dom_depth_limit_reached?
        super
    end

    def dom_depth_limit_reached?
        Options.scope.dom_depth_limit &&
            @page.dom.depth > Options.scope.dom_depth_limit
    end

end

end
end
