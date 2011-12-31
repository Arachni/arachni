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
    # Stdout formatter for the results of the HealthMap plugin
    #
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class HealthMap < Arachni::Plugin::Formatter

        def run
            print_status( 'URL health-map' )
            print_info( '~~~~~~~~~~~~~~~~' )

            print_line
            print_info( 'Legend:' )
            print_ok( 'No issues' )
            print_bad( 'Has issues' )
            print_line

            @results[:map].each {
                |i|

                state = i.keys[0]
                url   = i.values[0]

                if state == :unsafe
                    print_bad( url )
                else
                    print_ok( url )
                end
            }

            print_line

            print_info( 'Total: ' + @results[:total].to_s )
            print_ok( 'Without issues: ' + @results[:safe].to_s )
            print_bad( 'With issues: ' + @results[:unsafe].to_s +
                " ( #{@results[:issue_percentage].to_s}% )" )

            print_line

        end

    end

end
end

end
end
