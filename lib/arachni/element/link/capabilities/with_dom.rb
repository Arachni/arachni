=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Link
module Capabilities

# Extends {Arachni::Element::Capabilities::WithDOM} with {Link}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithDOM
    include Arachni::Element::Capabilities::WithDOM

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !dom_data

        super
    end

    private

    def dom_data
        return if !@source
        return @dom_data if @dom_data
        return if @dom_data == false

        # Don't bother parsing the source if it doesn't have anything interesting.
        if !(@source =~ /href=['"]?.*#.*?>/mi)
            return @dom_data = false
        end

        return if !node

        @dom_data ||= (self.class::DOM.data_from_node( node ) || false)
    end

end

end
end
end
