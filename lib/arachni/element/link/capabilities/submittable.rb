=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Link
module Capabilities

# Extends {Arachni::Element::Capabilities::Submittable} with {Link}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include Arachni::Element::Capabilities::Submittable

    # @note Will {Arachni::Options.rewrite} the `url`.
    # @note Will update the {#inputs} from the URL query.
    #
    # @param   (see Arachni::Element::Capabilities::Submittable#action=)
    #
    # @return  (see Arachni::Element::Capabilities::Submittable#action=)
    def action=( url )
        rewritten   = uri_parse( url ).rewrite
        self.inputs = rewritten.query_parameters.merge( self.inputs || {} )

        super rewritten.without_query
    end

end
end
end
end

