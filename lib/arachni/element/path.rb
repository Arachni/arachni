=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element
class Path < Base
    include Capabilities::WithAuditor

    def initialize( response )
        super url: response.url
        @initialized_options = response
    end

    def action
        url
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

end
end
