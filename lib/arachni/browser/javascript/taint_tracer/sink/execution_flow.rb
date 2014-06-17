=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser
class Javascript
class TaintTracer
class Sink

# Represents an execution-flow trace.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class ExecutionFlow < Base

    # @return   [Array]
    #   Data passed to the `TaintTracer#log_execution_flow_sink` JS interface.
    attr_accessor :data

end

end
end
end
end
end
