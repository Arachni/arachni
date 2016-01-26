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
module Auditable
    include Arachni::Element::Capabilities::Auditable

    def with_browser( &block )
        auditor.with_browser( &block )
    end

    def with_browser_cluster( &block )
        auditor.with_browser_cluster( &block )
    end

end

end
end
end
