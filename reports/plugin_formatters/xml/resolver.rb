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
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Resolver < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'resolver' )
            simple_tag( 'description', @description )

            start_tag( 'results' )

            @results.each {
                |hostname, ipaddress|
                __buffer( "<hostname value='#{hostname}' ipaddress='#{ipaddress}' />" )
            }

            end_tag( 'results' )
            end_tag( 'resolver' )

            return buffer( )
        end

    end

end
end

end
end
