=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'ap'

#
# Awesome prints an {AuditStore#to_hash} hash.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Reports::AP < Arachni::Report::Base

    def run
        print_line
        print_status 'Awesome printing AuditStore as a Hash...'

        ap report.to_hash

        print_status 'Done!'
    end

    def self.info
        {
            name:        'AP',
            description: %q{Awesome prints an AuditStore hash.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1'
        }
    end

end
