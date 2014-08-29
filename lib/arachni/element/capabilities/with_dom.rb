=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_node'

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithDOM
    include WithNode

    # @return     [DOM]
    attr_accessor :dom

    # @return   [DOM]
    def dom
        @dom ||= self.class::DOM.new( parent: self )
    end

    def dup
        copy_with_dom( super )
    end

    private

    def copy_with_dom( other )
        other.dom = dom.dup.tap { |d| d.parent = other } if @dom
        other
    end

end

end
end
