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
    include Arachni::Module::Output

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end


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

    def register_results( results )
        @framework.plugin_store( self, results )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Abstract plugin class',
            :description    => %q{Abstract plugin class.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                #                        option name       required?       description                     default
                # Arachni::OptBool.new( 'print_framework', [ false, 'Do you want to print the framework?', false ] ),
                # Arachni::OptString.new( 'my_name_is',    [ false, 'What\'s you name?', 'Tasos' ] ),
            ]
        }
    end

end

end
end
