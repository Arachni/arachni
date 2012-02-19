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
    # XML formatter for the results of the ContentTypes plugin
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version 0.1
    #
    class ContentTypes < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'content_types' )
            simple_tag( 'description', @description )

            start_tag( 'results' )
            @results.each_pair {
                |type, responses|

                start_content_type( type )

                responses.each {
                    |res|

                    start_tag( 'response' )

                    simple_tag( 'url', res[:url] )
                    simple_tag( 'method', res[:method] )

                    if res[:params] && res[:method].downcase == 'post'
                        start_tag( 'params' )
                        res[:params].each_pair {
                            |name, value|
                            add_param( name, value )
                        }
                        end_tag( 'params' )
                    end

                    end_tag( 'response' )
                }

                end_content_type
            }

            end_tag( 'results' )
            end_tag( 'content_types' )

            return buffer( )
        end

        def start_content_type( type )
            __buffer( "<content_type name=\"#{type}\">" )
        end

        def end_content_type
            __buffer( "</content_type>" )
        end


    end

end
end

end
end
