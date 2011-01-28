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
        # XML formatter for the results of the ContentTypes plugin
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class ContentTypes < Arachni::Plugin::Formatter

            include Buffer

            def initialize( plugin_data )
                @results     = plugin_data[:results]
                @description = plugin_data[:description]
            end

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
