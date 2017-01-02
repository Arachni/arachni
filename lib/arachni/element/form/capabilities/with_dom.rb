=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Form
module Capabilities

# Extends {Arachni::Element::Capabilities::WithDOM} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module WithDOM
    include Arachni::Element::Capabilities::WithDOM

    # @return   [DOM]
    def dom
        return if skip_dom?
        return @dom if @dom
        return if !node || inputs.empty?
        super
    end

end

end
end
end
