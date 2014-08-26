=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
class Browser
class Javascript
class TaintTracer
class Sink

# Represents an execution-flow trace.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
