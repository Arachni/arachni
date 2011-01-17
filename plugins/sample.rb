=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Sample plug-in to demo basic functionality.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Sample < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def prepare
        @dance =<<EODANCE

   _                             .-.
  / )  .-.    ___          __   (   )
 ( (  (   ) .'___)        (__'-._) (
  \ '._) (,'.'               '.     '-.
   '.      /  "\               '    -. '.
     )    /   \ \   .-.   ,'.   )  (  ',_)    _
   .'    (     \ \ (   \ . .' .'    )    .-. ( \
  (  .''. '.    \ \|  .' .' ,',--, /    (   ) ) )
   \ \   ', :    \    .-'  ( (  ( (     _) (,' /
    \ \   : :    )  / _     ' .  \ \  ,'      /
  ,' ,'   : ;   /  /,' '.   /.'  / / ( (\    (
  '.'      "   (    .-'. \       ''   \_)\    \
                \  |    \ \__             )    )
              ___\ |     \___;           /  , /
             /  ___)                    (  ( (
  PN         '.'                         ) ;) ;
                                        (_/(_/
EODANCE
    end

    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )

        if( @options['print_framework'] )
            print_info( "Here's the framework:" )
            pp @framework
        end

        if( @options['print_options'] )
            print_info( "Options:" )
            ap @options
        end

        if( @options['dance'] )
            print_info( @dance )
        end

    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Sample',
            :description    => %q{Sample plugin.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptBool.new( 'print_framework', [ false, 'Do you want to print the framework?', false ] ),
                Arachni::OptBool.new( 'print_options', [ false, 'Do you want to print the options?', true ] ),
                Arachni::OptBool.new( 'dance', [ false, 'Wanna dance?', false ] )
            ]
        }
    end

end

end
end
