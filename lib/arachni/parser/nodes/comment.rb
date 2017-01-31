=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative 'with_value'

module Arachni
class Parser
module Nodes

class Comment < Base
    include WithValue

    def text
        @value
    end

    def to_html( indentation = 2, level = 0 )
        indent = ' ' * (indentation * level)
        "#{indent}<!-- #{value} -->\n"
    end

end

end
end
end
