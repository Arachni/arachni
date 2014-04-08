=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'plugin/manager'

module RPC
class Server
module Plugin

#
# We need to extend the original Manager and redeclare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < ::Arachni::Plugin::Manager

    # make these inherited methods visible again
    private :available, :loaded, :results
    public  :available, :loaded, :results

    def load( plugins )
        if plugins.is_a?( Array )
            h = {}
            plugins.each { |p| h[p] = @framework.opts.plugins[p] || {} }
            plugins = h
        end

        plugins.each do |plugin, opts|
            prep_opts( plugin, self[plugin], opts )
        end

        @framework.opts.plugins.merge!( plugins )
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
