=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
    module PluginFormatters

        #
        # Stdout formatter for the results of the Profiler plugin
        #
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class Profiler < Arachni::Plugin::Formatter

            def initialize( plugin_data )
                @results = plugin_data[:results]
                @description = plugin_data[:description]
            end

            def run
                print_status( 'Profiler' )
                print_info( '~~~~~~~~~~~~~~' )

                print_info( 'Description: ' + @description )
                print_line

                print_info( 'Inputs affecting output:' )
                print_line

                @results['inputs'].each {
                    |item|

                    output = item['element']['type'].capitalize
                    output << " named '#{item['element']['name']}'" if item['element']['name']
                    output << " using the '#{item['element']['altered']}' input" if item['element']['altered']
                    output << " at '#{item['element']['owner']}' pointing to '#{item['element']['action']}'"
                    output << " using '#{item['request']['method']}'."

                    print_ok( output )
                    print_info( 'It was submitted using the following parameters:' )
                    item['element']['auditable'].each_pair {
                        |k, v|
                        print_info( "  * #{k}\t= #{v}" )
                    }

                    print_info
                    print_info( "The taint landed in the following elements at '#{item['request']['url']}':" )
                    item['landed'].each {
                        |elem|

                        output = elem['type'].capitalize
                        output << " named '#{elem['name']}'" if elem['name']
                        output << " using the '#{elem['altered']}' input" if elem['altered']
                        output << " at '#{elem['owner']}' pointing to '#{elem['action']}'" if elem['action']

                        print_info( "  * #{output}" )
                        if elem['auditable']
                            elem['auditable'].each_pair {
                                |k, v|
                                print_info( "    - #{k}\t= #{v}" )
                            }
                        end

                    }

                    print_line
                }

            end

        end

    end
end

end
end
