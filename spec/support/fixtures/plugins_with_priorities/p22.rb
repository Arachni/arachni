=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

class Arachni::Plugins::P22 < Arachni::Plugin::Base
    def self.info
        {
            name:     'P22',
            author:   'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            priority: 2
        }
    end
end
