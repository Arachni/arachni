=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Locatable

    def locator
        @locator ||= Arachni::Browser::ElementLocator.from_node( node )
    end

    # Locates the element in the page.
    def locate
        locator.locate( browser )
    end

end

end
end
end
