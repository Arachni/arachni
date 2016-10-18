=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_nodes'
require_relative 'attributes'

module Arachni
class Parser
module SAX
class Element
    include WithNodes

    attr_reader   :name
    attr_accessor :value
    attr_reader   :attributes

    def initialize( name )
        super()

        @name       = name.to_sym
        @value      = ''
        @attributes = Attributes.new
    end

    def []( name )
        @attributes[name]
    end

    def []=( name, value )
        @attributes[name] = value
    end

end
end
end
end
