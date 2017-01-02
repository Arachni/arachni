=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
