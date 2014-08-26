=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Plugins::P0 < Arachni::Plugin::Base
    def self.info
        {
            name:     'P0',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            priority: 0
        }
    end
end
