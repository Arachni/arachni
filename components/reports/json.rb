=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'json'

# Converts the AuditStore to a Hash which it then dumps in JSON format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
class Arachni::Reports::JSON < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            begin
                f.write ::JSON::pretty_generate( auditstore.to_h )
            rescue Encoding::UndefinedConversionError
                f.write ::JSON::pretty_generate( auditstore.to_h.recode )
            end
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'JSON',
            description:  %q{Exports the audit results as a JSON (.json) file.},
            content_type: 'application/json',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.1.3',
            options:      [ Options.outfile( '.json' ) ]
        }
    end

end
