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

class MetaModules
module MetaFormatters

    #
    # Stdout formatter for the results of the Uniformity metamodule
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Uniformity < Arachni::Plugin::Formatter

        def initialize( metadata )
            @results     = metadata[:results]
            @description = metadata[:description]
        end

        def run
            print_status( ' --- Uniformity (Lack of centralised sanitization):' )
            print_info( 'Description: ' + @description )

            print_line
            print_info( 'Relevant issues:' )
            print_info( '--------------------' )

            uniformals = @results['uniformals']
            pages      = @results['pages']

            uniformals.each_pair {
                |id, uniformal|

                issue = uniformal['issue']
                print_ok( "#{issue['name']} in #{issue['elem']} variable" +
                    " '#{issue['var']}' using #{issue['method']} at the following pages:" )

                pages[id].each_with_index {
                    |url, i|
                    print_info( url + " (Issue \##{uniformal['indices'][i]}" +
                        " - Hash ID: #{uniformal['hashes'][i]} )" )
                }

                print_line
            }
        end

    end

end
end
end
end
end
end
