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
module Mutable
    include Arachni::Element::Capabilities::Mutable

    private

    def prepare_mutation_options( options )
        options = super( options )
        # No sense in doing these for the DOM:
        #
        # Either payload will be raw in the first place or the browser will
        # override us.
        options.delete :with_raw_payloads
        # Browser handles the submission, there may not even be an HTTP request.
        options.delete :with_both_http_methods
        options
    end

end

end
end
end
