=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Cookie

module Capabilities

# Extends {Arachni::Element::Capabilities::WithDOM} with {Cookie}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithDOM
    include Arachni::Element::Capabilities::WithDOM

    # @return   [DOM]
    def dom
        return if inputs.empty?
        super
    end

end

end
end
end
