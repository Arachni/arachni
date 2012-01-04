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
    # XML formatter for the results of the WAF Detector plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class WAFDetector < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'waf_detector' )
            simple_tag( 'description', @description )

            start_tag( 'results' )

            simple_tag( 'message', @results[:msg] )
            simple_tag( 'code', @results[:code].to_s )

            end_tag( 'results' )
            end_tag( 'waf_detector' )

            return buffer( )
        end

    end

end
end

end
end
