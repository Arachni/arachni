=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
module PluginFormatters

    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Resolver < Arachni::Plugin::Formatter

        def run
            print_status( 'Resolver' )
            print_info( '~~~~~~~~~~~~~~' )

            print_info( 'Description: ' + @description )
            print_line

            @results.each {
                |hostname, ipaddress|
                print_info( hostname + ': ' + ipaddress )
            }
        end

    end

end
end

end
end
