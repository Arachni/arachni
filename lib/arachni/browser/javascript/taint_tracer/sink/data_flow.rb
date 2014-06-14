=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser
class Javascript
class TaintTracer
class Sink

# Represents an intercepted JS call due to {#tainted} {#arguments}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DataFlow < Base

    # @return   [String, nil]
    #   Source of the relevant function.
    attr_accessor :source

    # @return   [String]
    #   Name of the relevant function.
    attr_accessor :function

    # @return   [String]
    #   Name of the object containing {#function}.
    attr_accessor :object

    # @return   [Array]
    #   Arguments passed to the relevant function.
    attr_accessor :arguments

    # @return   [Object]
    #   Tainted value in {#arguments}.
    attr_accessor :tainted

    # @return   [String]
    #   Active taint.
    attr_accessor :taint

end

end
end
end
end
end
