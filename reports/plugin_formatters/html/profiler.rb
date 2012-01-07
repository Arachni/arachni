=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'json'

module Arachni

module Reports

class HTML
module PluginFormatters

    #
    # HTML formatter for the results of the Profiler plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.2
    #
    class Profiler < Arachni::Plugin::Formatter

        def run
            return ERB.new( IO.read( File.dirname( __FILE__ ) + '/profiler/template.erb' ) ).result( binding )
        end

    end

end
end

end
end
