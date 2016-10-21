=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_nodes/locate/traverse'

module Arachni
class Parser
module SAX
module WithNodes

    include Locate::Traverse

    attr_accessor :document
    attr_accessor :parent
    attr_accessor :children

    def initialize
        super()

        @children = []
    end

    def parent=( parent )
        @parent = parent
    end

    def <<( child )
        if !child.is_a?( String )
            child.parent = self
        end

        @children << child
    end

    def text
        children.find { |n| n.is_a? String }.to_s
    end

    def to_html( indentation = 2, level = 0 )
        indent = ' ' * (indentation * level)

        if @name == :comment
            "#{indent}<!-- #{value} -->\n"
        else
            html = "#{indent}<#{name}"

            attributes.each do |k, v|
                html << " #{k}=#{v.inspect}"
            end

            html << ">\n"

            children.each do |node|
                html << (node.is_a?( String ) ?
                    "#{' ' * (indentation * (level + 1))}#{node}\n" :
                    node.to_html( indentation, level + 1  ))
            end

            html << "#{indent}</#{name}>\n"
        end
    end


end
end
end
end
