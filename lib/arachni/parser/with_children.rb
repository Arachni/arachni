=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_children/search'

module Arachni
class Parser
module WithChildren

    include Search

    def children
        @children ||= []
    end

    def text
        txt = children.find { |n| n.is_a? Parser::Nodes::Text }
        return '' if !txt

        txt.value
    end

    def <<( child )
        child.parent = self
        children << child
    end

end
end
end
