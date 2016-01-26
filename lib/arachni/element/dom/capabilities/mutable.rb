=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable
    include Arachni::Element::Capabilities::Mutable

    private

    def prepare_mutation_options( options )
        options = super( options )
        # No sense in doing this for the DOM, either payload will be raw in the
        # first place or the browser will override us.
        options.delete :with_raw_payloads
        options
    end

end

end
end
end
