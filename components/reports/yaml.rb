=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Converts the AuditStore to a Hash which it then dumps in YAML format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
class Arachni::Reports::YAML < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( options['outfile'], 'w' ) do |f|
            f.write( report.to_hash.to_yaml )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'YAML',
            description:  %q{Exports the audit results as a YAML (.yaml) file.},
            content_type: 'application/x-yaml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.1',
            options:      [ Options.outfile( '.yaml' ) ]
        }
    end

end
