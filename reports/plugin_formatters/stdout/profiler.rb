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

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the Profiler plugin
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1
#
class PluginFormatters::Profiler < Arachni::Plugin::Formatter

    def run
        print_info 'Inputs affecting output:'
        print_line

        results.each do |item|
            output = item['element']['type'].capitalize
            output << " named '#{item['element']['name']}'" if item['element']['name']
            output << " using the '#{item['element']['altered']}' input" if item['element']['altered']
            output << " at '#{item['element']['owner']}' pointing to '#{item['element']['action']}'"
            output << " using '#{item['request']['method']}'."

            print_ok output

            print_info 'It was submitted using the following parameters:'
            item['element']['auditable'].each_pair { |k, v| print_info "  * #{k}\t= #{v}" }

            print_info
            print_info "The taint landed in the following elements at '#{item['request']['url']}':"
            item['landed'].each do |elem|

                output = elem['type'].capitalize
                output << " named '#{elem['name']}'" if elem['name']
                output << " using the '#{elem['altered']}' input" if elem['altered']
                output << " at '#{elem['owner']}' pointing to '#{elem['action']}'" if elem['action']

                print_info "  * #{output}"
                if elem['auditable']
                    elem['auditable'].each_pair { |k, v| print_info( "    - #{k}\t= #{v}" ) }
                end

            end
        end

    end

end
end
