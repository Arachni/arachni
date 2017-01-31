=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'plugin/manager'

module RPC
class Server

# @private
module Plugin

# We need to extend the original Manager and redeclare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager < ::Arachni::Plugin::Manager

    # make these inherited methods visible again
    private :available, :loaded, :results
    public  :available, :loaded, :results

    def load( plugins )
        if plugins.is_a?( Array )
            h = {}
            plugins.each { |p| h[p] = @framework.options.plugins[p] || {} }
            plugins = h
        end

        plugins.each do |plugin, opts|
            prepare_options( plugin, self[plugin], opts )
        end

        @framework.options.plugins.merge!( plugins )
        super( plugins.keys )
    end

    # Merges the plug-in results of multiple instances by delegating to
    # {Data::Plugins#merge_results}.
    def merge_results( results )
        Data.plugins.merge_results self, results
    end

end

end
end
end
end
