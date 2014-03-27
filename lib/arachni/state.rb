=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'state/issues'
require_relative 'state/audit'
require_relative 'state/element_filter'

module Arachni

# Stores and provides access to the state of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class State

    # {State} error namespace.
    #
    # All {State} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

class <<self

    # @return   [Issues]
    attr_reader :issues

    # @return   [Audit]
    attr_reader :audit

    # @return   [ElementFilter]
    attr_reader :element_filter

    def reset
        @issues         = Issues.new
        @audit          = Audit.new
        @element_filter = ElementFilter.new
    end
    alias :clear :reset

end
reset
end
end
