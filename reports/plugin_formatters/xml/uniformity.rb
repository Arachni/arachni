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
# XML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter
    include Buffer

    def run
        uniformals = results['uniformals']

        uniformals.each do |id, uniformal|
            start_uniformals id

            uniformal['hashes'].each_with_index do |hash, i|
                add_uniformal( i, uniformal )
            end

            end_tag 'uniformals'
        end

        buffer
    end

    def add_uniformal( idx, uniformal )
        append "<issue index=\"#{uniformal['indices'][idx]}\"" +
            " hash=\"#{uniformal['hashes'][idx]}\" />"
    end

    def start_uniformals( id )
        append "<uniformals id=\"#{id}\">"
    end


end
end
