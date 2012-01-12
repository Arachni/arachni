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
    # XML formatter for the results of the Discovery plugin.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Discovery < Arachni::Plugin::Formatter

        include Arachni::Reports::Buffer

        def run
            start_tag( 'discovery' )
            simple_tag( 'description', @description )
            start_tag( 'results' )

            @results.each { |issue| add_issue( issue ) }

            end_tag( 'results' )
            end_tag( 'discovery' )
        end

        def add_issue( issue )
            __buffer( "<issue hash=\"#{issue['hash'].to_s}\" " +
                " index=\"#{issue['index'].to_s}\" name=\"#{issue['name']}\"" +
                " url=\"#{issue['url']}\" />" )
        end

    end

end
end
end
end
