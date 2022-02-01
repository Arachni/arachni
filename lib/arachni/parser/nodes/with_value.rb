=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Parser
module Nodes

module WithValue

    attr_reader :value

    def initialize( value )
        self.value = value
    end

    def value=( v )
        @value = v.recode.strip.freeze
    end

end

end
end
end
