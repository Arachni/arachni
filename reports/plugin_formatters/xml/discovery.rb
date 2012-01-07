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
    # XML formatter for the results of the Discovery plugin.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Discovery < Arachni::Plugin::Formatter

        include Arachni::Reports::Buffer

        def run
            start_tag( 'discovery' )
            simple_tag( 'description', @description )
            start_tag( 'results' )

            @results.each { |issue| add_issue( issue ) }

            end_tag( 'results' )
            end_tag( 'discovery' )
        end

        def add_issue( issue )
            __buffer( "<issue hash=\"#{issue['hash'].to_s}\" " +
                " index=\"#{issue['index'].to_s}\" name=\"#{issue['name']}\"" +
                " url=\"#{issue['url']}\" />" )
        end

    end

end
end
end
end
