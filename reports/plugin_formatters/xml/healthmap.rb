=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

class Arachni::Reports::XML

#
# XML formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter
    include Buffer

    def run
        start_tag 'map'
        results[:map].each do |i|
            state = i.keys[0]
            url   = i.values[0]

            if state == :unsafe
                add_url( 'unsafe', url )
            else
                add_url( 'safe', url )
            end
        end
        end_tag 'map'

        start_tag 'stats'
        simple_tag( 'total', results[:total] )
        simple_tag( 'safe', results[:safe] )
        simple_tag( 'unsafe', results[:unsafe] )
        simple_tag( 'issue_percentage', results[:issue_percentage] )
        end_tag 'stats'

        buffer
    end

    def add_url( type, url )
        append "<entry state=\"#{type}\" url=\"#{escape( url )}\" />"
    end


end

end
