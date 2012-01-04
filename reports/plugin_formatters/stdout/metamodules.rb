=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
module PluginFormatters

    #
    # Stdout formatter for the results of the MetaModules plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
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
