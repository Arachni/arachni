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
# Demo plugin; clears the standard output based on an interval while the framework is running.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ClearStdout < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def run( )

        print_debug "[BEFORE] Scanning?: #{@framework.running?}"

        while( @framework.running? )

            print_debug "[WHILE] Scanning?: #{@framework.running?}"

            # print a bunch of new lines
            80.times{ print_line }

            ::IO.select( nil, nil, nil, @options['interval'] )
        end

        print_debug "[AFTER] Scanning?: #{@framework.running?}"
    end

    def self.info
        {
            :name           => 'ClearStdout',
            :description    => %q{Clears standard output.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptInt.new( 'interval', [ false, 'How often do you want clear?', 2 ] ),
            ]
        }
    end

end

end
end
