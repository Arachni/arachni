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
        # Stdout formatter for the results of the ContentTypes plugin
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class ContentTypes < Arachni::Plugin::Formatter

            def initialize( plugin_data )
                @results     = plugin_data[:results]
                @description = plugin_data[:description]
            end

            def run
                print_status( 'Content-types' )
                print_info( '~~~~~~~~~~~~~~~~~~~~~~~~~~' )

                print_info( 'Description: ' + @description )
                print_line

                @results.each_pair {
                    |type, responses|

                    print_ok( type )

                    responses.each {
                        |res|
                        print_status( "    URL:    " + res[:url] )
                        print_info( "    Method: " + res[:method] )

                        if res[:params] && res[:method].downcase == 'post'
                            print_info( "    Parameters:" )
                            res[:params].each_pair {
                                |k, v|
                                print_info( "        #{k} => #{v}" )
                            }
                        end

                        print_line
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
