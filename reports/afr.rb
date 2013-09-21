=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Arachni Framework Report (.afr)
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Reports::AFR < Arachni::Report::Base

    def run
        print_line
        print_status "Dumping audit results in '#{outfile}'."

        auditstore.save( outfile )

        print_status 'Done!'
    end

    def self.info
        {
            name:        'Arachni',
            description: %q{Exports the audit results as an Arachni Framework Report (.afr) file.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            options:     [ Arachni::Report::Options.outfile( '.afr' ) ]
        }
    end

end
