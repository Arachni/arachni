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
# XML formatter for the results of the Profiler plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Profiler < Arachni::Plugin::Formatter
    include Buffer

    def run
        start_tag 'inputs'
        results.each do |item|
            start_tag 'input'

            start_tag 'element'
            add_hash item['element']
            add_params( item['element']['auditable'] ) if item['auditable']
            end_tag 'element'

            start_tag 'response'
            add_hash item['response']
            add_headers( 'headers', item['response']['headers'] )
            end_tag 'response'

            start_tag 'request'
            add_hash item['response']
            add_headers( 'headers', item['request']['headers'] )
            end_tag 'request'

            start_tag 'landed'
            item['landed'].each do |elem|
                start_tag 'element'
                add_hash elem
                add_params( elem['auditable'] ) if elem['auditable']
                end_tag 'element'
            end

            end_tag 'landed'
            end_tag 'input'
        end

        end_tag 'inputs'

        buffer
    end

    def add_hash( hash )
        hash.each_pair do |k, v|
            next if v.nil? || v.is_a?( Hash ) || v.is_a?( Array )
            simple_tag( k, v )
        end
    end

    def add_params( params )
        start_tag 'params'
        params.each do |name, value|
            append "<param name=\"#{name}\" value=\"#{escape( value )}\" />"
        end
        end_tag 'params'
    end

end
end
