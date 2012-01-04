=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
    # XML formatter for the results of the HealthMap plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class HealthMap < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'healthmap' )
            simple_tag( 'description', @description )

            start_tag( 'results' )
            start_tag( 'map' )
            @results[:map].each {
                |i|

                state = i.keys[0]
                url   = i.values[0]

                if state == :unsafe
                    add_url( 'unsafe', url )
                else
                    add_url( 'safe', url )
                end
            }
            end_tag( 'map' )

            start_tag( 'stats' )

            simple_tag( 'total', @results[:total].to_s )
            simple_tag( 'safe', @results[:safe].to_s )
            simple_tag( 'unsafe', @results[:unsafe].to_s )
            simple_tag( 'issue_percentage', @results[:issue_percentage].to_s )

            end_tag( 'stats' )
            end_tag( 'results' )
            end_tag( 'healthmap' )

            return buffer( )
        end

        def add_url( type, url )
            __buffer( "<entry state=\"#{type}\" url=\"#{url}\" />" )
        end


    end

end
end

end
end
