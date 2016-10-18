=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'locate/lookup'
require_relative 'locate/traverse'

module Arachni
class Parser
module SAX
module WithNodes

    include Locate::Traverse
    # include Locate::LookUp

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

            push_child child
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

    private

    def fail_if_not_in_whitelist( name )
        return if !document || document.whitelisted?( name )

        fail "Element '#{name}' not in whitelist."
    end

end
end
end
end
