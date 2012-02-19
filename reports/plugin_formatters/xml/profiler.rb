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
    # XML formatter for the results of the Profiler plugin
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1.1
    #
    class Profiler < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'profiler' )
            simple_tag( 'description', @description )

            start_tag( 'results' )

            start_tag( 'inputs' )
            @results['inputs'].each {
                |item|

                start_tag( 'input' )

                start_tag( 'element' )
                add_hash( item['element'] )
                add_params( item['element']['auditable'] ) if item['auditable']
                end_tag( 'element' )

                start_tag( 'response' )
                add_hash( item['response'] )
                add_headers( 'headers', item['response']['headers'] )
                end_tag( 'response' )

                start_tag( 'request' )
                add_hash( item['response'] )
                add_headers( 'headers', item['request']['headers'] )
                end_tag( 'request' )

                start_tag( 'landed' )
                item['landed'].each {
                    |elem|
                    start_tag( 'element' )
                    add_hash( elem )
                    add_params( elem['auditable'] ) if elem['auditable']
                    end_tag( 'element' )
                }
                end_tag( 'landed' )


                end_tag( 'input' )
            }
            end_tag( 'inputs' )

            end_tag( 'results' )
            end_tag( 'profiler' )

            return buffer( )
        end

        def add_hash( hash )
            hash.each_pair {
                |k, v|
                next if v.nil? || v.is_a?( Hash ) || v.is_a?( Array )
                simple_tag( k, v.to_s )
            }
        end

        def add_params( params )

            start_tag( 'params' )
            params.each_pair {
                |name, value|
                __buffer( "<param name=\"#{name}\" value=\"#{CGI.escapeHTML( value || '' )}\" />" )
            }
            end_tag( 'params' )
        end

    end

end
end

end
end
