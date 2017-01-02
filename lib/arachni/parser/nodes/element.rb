=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative '../with_children'

module Arachni
class Parser
module Nodes

class Element < Base
    require_relative 'element/with_attributes'

    include WithChildren
    include WithAttributes

    attr_reader :name

    def initialize( name )
        @name = name.downcase.to_sym
    end

    def to_html( indentation = 2, level = 0 )
        indent = ' ' * (indentation * level)

        html = "#{indent}<#{name}"

        attributes.each do |k, v|
            html << " #{k}=#{v.inspect}"
        end

        html << ">\n"
        children.each do |node|
            html << node.to_html( indentation, level + 1  )
        end
        html << "#{indent}</#{name}>\n"
    end

end

end
end
end
