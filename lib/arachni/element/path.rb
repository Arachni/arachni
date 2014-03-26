=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element
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
