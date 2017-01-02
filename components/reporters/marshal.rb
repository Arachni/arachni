=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Converts the Report to a Hash which it then dumps in Marshal format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.2
class Arachni::Reporters::Marshal < Arachni::Reporter::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            f.write ::Marshal::dump( report.to_hash )
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'Marshal',
            description:  %q{Exports the audit results as a Marshal (.marshal) file.},
            content_type: 'application/x-marshal',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:      '0.1.1',
            options:      [Options.outfile('.marshal')]
        }
    end

end
