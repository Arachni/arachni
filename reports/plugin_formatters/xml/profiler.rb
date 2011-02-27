=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Arachni::Options.instance.dir['reports'] + '/xml/buffer.rb'

module Reports

class XML
    module PluginFormatters

        #
        # XML formatter for the results of the Profiler plugin
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class Profiler < Arachni::Plugin::Formatter

            include Buffer

            def initialize( plugin_data )
                @results     = plugin_data[:results]
                @description = plugin_data[:description]
            end

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

                start_tag( 'times' )
                @results['times'].each {
                    |elem|
                    start_tag( 'response' )
                    add_hash( elem )
                    add_params( elem['params'] ) if elem['params']
                    end_tag( 'response' )
                }
                end_tag( 'times' )


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
                    __buffer( "<param name=\"#{name}\" value=\"#{CGI.escapeHTML( value.strip )}\" />" )
                }
                end_tag( 'params' )
            end

        end

    end
end

end
end
