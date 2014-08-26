=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithScope

    require_relative 'with_scope/scope'

    # @return   [Scope]
    def scope
        @scope ||= Scope.new( self )
    end

end

end
end
