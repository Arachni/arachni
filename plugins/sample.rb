=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

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

    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )

        print_line( )
        print_info( "Here's the framework:" )
        pp @framework

        print_info( "Options:" )
        pp @options
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
        }
    end

end

end
end
