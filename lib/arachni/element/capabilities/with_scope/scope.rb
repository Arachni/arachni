=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Element::Capabilities
module WithScope

# Determines the {Scope scope} status of {Element::Base elements} based on
# their {Element::Base#action}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < URI::Scope

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < URI::Scope::Error
    end

    def initialize( element )
        super Arachni::URI( element.action )
    end

    # @note Will call {URI::Scope#redundant?}.
    #
    # @return   (see URI::Scope#out?)
    def out?
        super || redundant?
    end

end

end
end
end
