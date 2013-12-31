=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element
class Path < Base

    attr_accessor :auditor

    def initialize( response )
        @response = response
        super url: response.url
    end

    def action
        url
    end

    def remove_auditor
        @auditor = nil
    end

    def dup
        self.class.new @response
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

end
end
