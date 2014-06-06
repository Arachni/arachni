=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithScope

    require_relative 'with_scope/scope'

    # @return   [Scope]
    def scope
        @scope ||= Scope.new( self )
    end

end

end
end
