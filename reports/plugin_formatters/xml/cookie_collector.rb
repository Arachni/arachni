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
# XML formatter for the results of the CookieCollector plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class PluginFormatters::CookieCollector < Arachni::Plugin::Formatter
    include Buffer

    def run
        results.each_with_index do |result, i|
            start_tag 'response'

            simple_tag( 'time', result[:time].to_s )
            simple_tag( 'url', result[:res]['effective_url'] )

            start_tag 'cookies'
            result[:cookies].each { |name, value| add_cookie( name, value ) }
            end_tag 'cookies'

            end_tag 'response'
        end

        buffer
    end

end
end
