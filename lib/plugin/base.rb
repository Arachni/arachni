=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugin

#
# Arachni::Plugin::Base class
#
# An abstract class for the plugins.<br/>
# All plugins must extend this.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
# @abstract
#
class Base

    # get the output interface
    include Arachni::UI::Output

    #
    # OPTIONAL
    #
    def prepare( )

    end

    #
    # REQUIRED
    #
    def run( )

    end

    #
    # OPTIONAL
    #
    def clean_up( )

    end


    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'Abstract plugin class.',

            #
            # you can provide the user with options to allow him to
            # customize the report to his needs.
            #
            # Arachni doesn't do any checking whatsoever.
            #
            'Options'        => {
                # option name
                'option_one_something' =>
                    [   # the available values for the option
                        'true/false (Default: true)',
                        # the description of the option
                        'Do something?'
                    ],
                'option_two_something' =>
                    [
                        '1..inf (Default: inf)',
                        'How many times to do something?'
                    ]
            },
            'Description'    => %q{This class should be extended by all plugins.},
            'Author'         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            'Version'        => '0.1',
        }
    end

end

end
end
