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
    # Stdout formatter for the results of the CookieCollector plugin
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      
    # @version 0.1
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
