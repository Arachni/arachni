=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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

    def each_mutation( payload, options = {}, &block )
        # No sense in doing this for the DOM, either payload will be raw in the
        # first place or the browser will override us.
        options.delete :with_raw_payloads

        super( payload, options, &block )
    end

end

end
end
end
