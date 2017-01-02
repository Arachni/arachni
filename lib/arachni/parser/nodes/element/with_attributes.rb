=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_attributes/attributes'

module Arachni
class Parser
module Nodes
class Element

module WithAttributes

    def attributes
        @attributes ||= Attributes.new
    end

    def []( name )
        attributes[name]
    end

    def []=( name, value )
        attributes[name] = value
    end

end

end
end
end
end
