=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Link
module Capabilities

# Extends {Arachni::Element::Capabilities::Auditable} with {Link}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Auditable
    include Arachni::Element::Capabilities::Auditable

    def coverage_id
        dom_data ? "#{super}:#{dom_data[:inputs].keys.sort}" : super
    end

end
end
end
end
