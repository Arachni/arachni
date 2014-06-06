=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities
module WithScope

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Scope < URI::Scope

    def initialize( element )
        super Arachni::URI( element.action )
    end

    # @note Will call {URI::Scope#redundant?}.
    def out?
        super || redundant?
    end

end

end
end
end
