=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Creates a plain text report of the audit.
#
# It redirects stdout to an outfile and runs the default (stdout.rb) report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
class Arachni::Reports::Text < Arachni::Report::Base

    def run
        load Arachni::Options.paths.reports + 'stdout.rb'

        print_line
        print_status "Dumping audit results in #{outfile}."

        # redirect output streams to the outfile
        stdout  = $stdout.dup
        stderr  = $stderr.dup
        $stderr = $stdout = File.new( outfile, 'w' )

        Reports::Stdout.new( report, options ).run

        $stdout.close
        $stdout = stdout.dup
        $stderr = stderr.dup

        print_status 'Done!'
    end

    def self.info
        {
            name:        'Text',
            description: %q{Exports the audit results as a text (.txt) file.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',
            options:     [ Options.outfile( '.txt' ) ]
        }
    end

end
