=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents an auditable path element, currently a placeholder for a vulnerable
# path vector.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Path < Base
    include Capabilities::WithAuditor

    def initialize( url )
        super url: url
        @initialization_options = url
    end

    def action
        url
    end

end
end
