=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Plugins::Wait < Arachni::Plugin::Base

    def run
        wait_while_framework_running
        register_results( 'stuff' => true )
    end

    def self.info
        {
            name:        'Wait',
            description: %q{},
            tags:        ['wait_string', :wait_sym],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
