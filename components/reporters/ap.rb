=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'ap'

#
# Awesome prints an {Report#to_hash} hash.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Reporters::AP < Arachni::Reporter::Base

    def run
        print_line
        print_status 'Awesome printing Report as a Hash...'

        ap report.to_hash

        print_status 'Done!'
    end

    def self.info
        {
            name:        'AP',
            description: %q{Awesome prints a scan report hash.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1'
        }
    end

end
