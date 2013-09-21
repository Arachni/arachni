=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Beeps when the scan finishes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Plugins::BeepNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running
        options['repeat'].times {
            sleep options['interval']
            print_info 'Beep!'
            print 7.chr
        }
    end

    def self.info
        {
            name: 'Beep notify',
            description: %q{It beeps when the scan finishes.},
            author: 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version: '0.1',
            options: [
                Options::Int.new( 'repeat', [false, 'How many times to beep.', 4] ),
                Options::Float.new( 'interval', [false, 'How long to wait between beeps.', 0.4] )
            ]

        }
    end

end
