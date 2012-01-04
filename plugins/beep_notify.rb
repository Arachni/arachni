=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Beeps when the scan finishes.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class BeepNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running
        @options['repeat'].times {
            sleep @options['interval']
            print_info( "Beep!" )
            print 7.chr
        }

    end

    def self.info
        {
            :name           => 'Beep notify',
            :description    => %q{It beeps when the scan finishes.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptInt.new( 'repeat', [ false, 'How many times to beep.', 4 ] ),
                Arachni::OptFloat.new( 'interval', [ false, 'How long to wait between beeps.', 0.4 ] ),
            ]

        }
    end

end

end
end
