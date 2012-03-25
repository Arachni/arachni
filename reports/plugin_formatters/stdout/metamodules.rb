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
module Reports

class Stdout
module PluginFormatters

    #
    # Stdout formatter for the results of the MetaModules plugin
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      
    # @version 0.1
    #
    class MetaModules < Arachni::Plugin::Formatter

        def run
            print_status( 'Meta-Modules' )
            print_info( '~~~~~~~~~~~~~~' )

            print_info( 'Description: ' + @description )
            print_line

            format_meta_results( @results )

            print_line
        end

        #
        # Runs plugin formatters for the running report and returns a hash
        # with the prepared/formatted results.
        #
        # @param    [AuditStore#plugins]      plugins   plugin data/results
        #
        def format_meta_results( plugins )

            ancestor = self.class.ancestors[0]

            # add the PluginFormatters module to the report
            eval( "module  MetaFormatters end" )

            # prepare the directory of the formatters for the running report
            lib = File.dirname( __FILE__ ) + '/metaformatters/'

            @@formatters ||= {}
            # initialize a new component manager to handle the plugin formatters
            @@formatters[ancestor] ||= ::Arachni::Report::FormatterManager.new( lib, ancestor.const_get( 'MetaFormatters' ) )

            # load all the formatters
            @@formatters[ancestor].load( ['*'] ) if @@formatters[ancestor].empty?

            # run the formatters and gather the formatted data they return
            formatted = {}
            @@formatters[ancestor].each_pair {
                |name, formatter|
                plugin_results = plugins[name]
                next if !plugin_results || plugin_results[:results].empty?

                formatted[name] = formatter.new( plugin_results.deep_clone ).run
            }

            return formatted
        end


    end

end
end

end
end
