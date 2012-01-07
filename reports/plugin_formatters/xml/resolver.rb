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
    # @author: Tasos "Zapotek" Laskos
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
