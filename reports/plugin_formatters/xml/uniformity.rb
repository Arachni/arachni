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
    # XML formatter for the results of the Uniformity plugin.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Uniformity < Arachni::Plugin::Formatter

        include Arachni::Reports::Buffer

        def run
            start_tag( 'uniformity' )
            simple_tag( 'description', @description )
            start_tag( 'results' )

            uniformals = @results['uniformals']
            pages      = @results['pages']

            uniformals.each_pair {
                |id, uniformal|

                start_uniformals( id )

                uniformal['hashes'].each_with_index {
                    |hash, i|
                    add_uniformal( i, uniformal )
                }

                end_tag( 'uniformals' )
            }

            end_tag( 'results' )
            end_tag( 'uniformity' )
        end

        def add_uniformal( idx, uniformal )
            __buffer( "<issue index=\"#{uniformal['indices'][idx]}\"" +
                " hash=\"#{uniformal['hashes'][idx]}\" />" )
        end

        def start_uniformals( id )
            __buffer( "<uniformals id=\"#{id}\">" )
        end


    end

end
end
end
end
