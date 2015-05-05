=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'resource_exploration'

module Arachni
class BrowserCluster
module Jobs

# Traces a {#taint} throughout the JS environment of the given {#resource}.
# It also allows {#injector custom JS code} to be executed under the same scope
# in order to directly introduce the {#taint}.
#
# It will pass each evaluated page with the {TaintTrace::Result result}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class TaintTrace < ResourceExploration

    require_relative 'taint_trace/result'
    require_relative 'taint_trace/event_trigger'

    # @return [String]
    #   Taint to trace throughout the data-flow of the JS environment.
    attr_accessor :taint

    # @return [String]
    #   JS code to execute in order to introduce the taint.
    attr_accessor :injector

    def run
        browser.javascript.taint       = self.taint
        browser.javascript.custom_code = self.injector

        browser.on_new_page_with_sink { |page| save_result( page: page ) }

        super
    end

    def to_s
        "#<#{self.class}:#{object_id} @resource=#{@resource} " +
            "@taint=#{@taint.inspect} @injector=#{@injector.inspect}>"
    end
    alias :inspect :to_s

end

end
end
end
