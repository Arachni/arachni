=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'state/issues'
require_relative 'state/audit'

module Arachni

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

    attr_reader :issues
    attr_reader :audit

    def reset
        @issues = Issues.new
        @audit  = Audit.new
    end
    alias :clear :reset

end
reset
end
end
