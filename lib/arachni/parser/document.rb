=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_children'
require_relative 'nodes/comment'
require_relative 'nodes/text'
require_relative 'nodes/element'

module Arachni
class Parser
class Document

    include WithChildren

    def name
        :document
    end

    def to_html( indentation = 2, level = 0 )
        html = "<!DOCTYPE html>\n"
        children.each do |child|
            html << child.to_html( indentation, level )
        end
        html << "\n"
    end

end
end
end
