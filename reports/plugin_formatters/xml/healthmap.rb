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

require Arachni::Options.instance.dir['reports'] + '/xml/buffer.rb'

module Reports

class XML
module PluginFormatters

    #
    # XML formatter for the results of the HealthMap plugin
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version 0.1
    #
    class HealthMap < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'healthmap' )
            simple_tag( 'description', @description )

            start_tag( 'results' )
            start_tag( 'map' )
            @results[:map].each {
                |i|

                state = i.keys[0]
                url   = i.values[0]

                if state == :unsafe
                    add_url( 'unsafe', url )
                else
                    add_url( 'safe', url )
                end
            }
            end_tag( 'map' )

            start_tag( 'stats' )

            simple_tag( 'total', @results[:total].to_s )
            simple_tag( 'safe', @results[:safe].to_s )
            simple_tag( 'unsafe', @results[:unsafe].to_s )
            simple_tag( 'issue_percentage', @results[:issue_percentage].to_s )

            end_tag( 'stats' )
            end_tag( 'results' )
            end_tag( 'healthmap' )

            return buffer( )
        end

        def add_url( type, url )
            __buffer( "<entry state=\"#{type}\" url=\"#{url}\" />" )
        end


    end

end
end

end
end
