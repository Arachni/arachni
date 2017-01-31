=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Form
module Capabilities

# Extends {Arachni::Element::Capabilities::Submittable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include Arachni::Element::Capabilities::Submittable

    # @param    (see Arachni::Element::Capabilities::Submittable#action=)
    # @@return  (see Arachni::Element::Capabilities::Submittable#action=)
    def action=( url )
        if self.method == :get
            rewritten   = uri_parse( url ).rewrite
            self.inputs = rewritten.query_parameters.merge( self.inputs || {} )

            super rewritten.without_query
        else
            super url
        end
    end

end
end
end
end
