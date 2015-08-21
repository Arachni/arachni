=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Input < Base
    require_relative 'input/dom'

    include Arachni::Element::Capabilities::DOMOnly

    def self.type
        :input
    end

end
end
