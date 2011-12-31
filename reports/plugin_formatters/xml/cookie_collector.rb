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
    # XML formatter for the results of the CookieCollector plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class CookieCollector < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'cookie_collector' )
            simple_tag( 'description', @description )

            start_tag( 'results' )
            @results.each_with_index {
                |result, i|

                start_tag( 'response' )
                simple_tag( 'time', result[:time].to_s )
                simple_tag( 'url', result[:res]['effective_url'] )

                start_tag( 'cookies' )
                result[:cookies].each_pair{
                    |name, value|
                    add_cookie( name, value )
                }
                end_tag( 'cookies' )
                end_tag( 'response' )
            }
            end_tag( 'results' )

            end_tag( 'cookie_collector' )

            return buffer( )
        end

    end

end
end

end
end
