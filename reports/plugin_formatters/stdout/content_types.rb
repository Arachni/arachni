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
    # Stdout formatter for the results of the ContentTypes plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class ContentTypes < Arachni::Plugin::Formatter

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
