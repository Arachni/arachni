=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

require Options.instance.dir['lib'] + 'plugin/manager'

module RPC
class Server
module Plugin

#
# We need to extend the original Manager and redeclare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Manager < ::Arachni::Plugin::Manager

    # make these inherited methods visible again
    private :available, :results, :loaded
    public  :available, :results, :loaded

    def initialize( framework )
        super( framework )

        @plugin_opts = {}
    end

    def load( plugins )
        @plugin_opts.merge!( plugins )
        super( plugins.keys )

        @framework.opts.plugins = plugins
    end

    def create( name )
        self[name].new( @framework, prep_opts( name, self[name], @plugin_opts[name] ) )
    end

    #
    # Merges the plug-in results of self with the provided results.
    #
    # It uses each plugin's merge() class method to do it.
    #
    # @param    [Array]     results
    #
    def merge_results!( results )
        info = {}
        formatted = {}

        results << @@results
        results.each {
            |plugins|

            plugins.each {
                |name, res|
                next if !res

                formatted[name] ||= []
                formatted[name] << res[:results]

                info[name] = res.reject{ |k, v| k == :results } if !info[name]
            }
        }

        merged = {}
        formatted.each {
            |plugin, results|

            if !self[plugin].distributable?
                res = results[0]
            else
                res = self[plugin].merge( results )
            end
            merged[plugin] = info[plugin].merge( :results => res )
        }

        @@results = merged
    end

end

end
end
end
end
