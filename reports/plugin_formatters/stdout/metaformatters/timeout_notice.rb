module Arachni
module Reports

class Stdout
module PluginFormatters

class MetaModules
module MetaFormatters

    #
    # Stdout formatter for the results of the CookieCollector plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class TimeoutNotice < Arachni::Plugin::Formatter

        def initialize( metadata )
            @results     = metadata[:results]
            @description = metadata[:description]
        end

        def run
            print_status( ' --- Timeout notice:' )
            print_info( 'Description: ' + @description )

            print_line
            print_info( 'Relevant issues:' )
            print_info( '--------------------' )
            @results.each {
                |issue|
                print_ok( "[\##{issue['index']}] #{issue['name']} at #{issue['url']} in #{issue['elem']} variable '#{issue['var']}' using #{issue['method']}." )
            }
        end

    end

end
end
end
end
end
end
