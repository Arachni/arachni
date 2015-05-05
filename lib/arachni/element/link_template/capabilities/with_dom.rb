=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class LinkTemplate
module Capabilities

# Extends {Arachni::Element::Capabilities::WithDOM} with {LinkTemplate}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithDOM
    include Arachni::Element::Capabilities::WithNode
    include Arachni::Element::Capabilities::WithDOM

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !dom_data

        super
    end

    private

    def dom_data
        return @dom_data if @dom_data
        return if @dom_data == false
        return if !node

        @dom_data ||= (self.class::DOM.data_from_node( node ) || false)
    end
end

end
end
end
