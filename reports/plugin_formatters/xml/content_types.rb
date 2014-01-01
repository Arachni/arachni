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
# XML formatter for the results of the ContentTypes plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::ContentTypes < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each_pair do |type, responses|
            start_content_type( type )

            responses.each do |res|
                start_tag 'response'

                simple_tag( 'url', res[:url] )
                simple_tag( 'method', res[:method] )

                if res[:params] && res[:method].downcase == 'post'
                    start_tag 'params'
                    res[:params].each { |name, value| add_param( name, value ) }
                    end_tag 'params'
                end

                end_tag 'response'
            end

            end_content_type
        end

        buffer
    end

    def start_content_type( type )
        append "<content_type name=\"#{type}\">"
    end

    def end_content_type
        append "</content_type>"
    end

end
end
