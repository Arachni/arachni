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
    # Stdout formatter for the results of the CookieCollector plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class CookieCollector < Arachni::Plugin::Formatter

        def run
            print_status( 'Cookie collector' )
            print_info( '~~~~~~~~~~~~~~~~~~' )

            print_info( 'Description: ' + @description )
            print_line

            @results.each_with_index {
                |result, i|

                print_info( "[#{(i + 1).to_s}] On #{result[:time]}" )
                print_info( "URL: " + result[:res]['effective_url'] )
                print_info( 'Cookies forced to: ' )
                result[:cookies].each_pair{
                    |name, value|
                    print_info( "    #{name} => #{value}" )
                }
                print_line
            }

            print_line
        end

    end

end
end

end
end
