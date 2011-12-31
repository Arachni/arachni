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
    # XML formatter for the results of the FormDicattack plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class FormDicattack < Arachni::Plugin::Formatter

        include Buffer

        def run
            start_tag( 'form_dicattack' )
            simple_tag( 'description', @description )

            start_tag( 'results' )

            add_credentials( @results[:username], @results[:password] )

            end_tag( 'results' )
            end_tag( 'form_dicattack' )

            return buffer( )
        end

    end

end
end

end
end
