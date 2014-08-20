=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Plugins::P00 < Arachni::Plugin::Base
    def self.info
        {
            name:     'P00',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            priority: 0
        }
    end
end
