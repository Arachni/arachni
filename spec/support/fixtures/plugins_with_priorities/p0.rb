=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Plugins::P0 < Arachni::Plugin::Base
    def self.info
        {
            name:     'P0',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            priority: 0
        }
    end
end
