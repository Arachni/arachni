=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports

class Stdout
module PluginFormatters

    #
    # Stdout formatter for the results of the FormDicattack plugin
    #
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class FormDicattack < Arachni::Plugin::Formatter

        def run
            print_status( 'Form dictionary attacker' )
            print_info( '~~~~~~~~~~~~~~~~~~~~~~~~~~' )

            print_info( 'Description: ' + @description )
            print_line
            print_info( "Cracked credentials:" )
            print_ok( '    Username: ' + @results[:username] ) if @results[:username]
            print_ok( '    Password: ' + @results[:password] ) if @results[:password]

            print_line
        end

    end

end
end

end
end
