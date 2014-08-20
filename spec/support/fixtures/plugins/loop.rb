=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Plugins::Loop < Arachni::Plugin::Base

    def run
        loop { sleep 1 }
    end

    def self.info
        {
            name:        '',
            description: %q{},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1'
        }
    end

end
